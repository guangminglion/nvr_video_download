defmodule NvrMngtWeb.NvrController do
  import SweetXml

  use NvrMngtWeb, :controller
  require Logger

  def index(conn, _params) do
    render conn, "index.html"
  end

  def download_videos(conn, params) do
    IO.inspect(params)
    %{"user"=>  %{"nvrid" => nvrid,"host" => host,"port" => port,"username" => username,"password" => password,
    "channel" => channel, "starttime" => starttime, "endtime" => endtime, } }=params

      get_stream_urls("1", host, port, username, password, 1, starttime,endtime,nvrid)


    render conn, "index.html"

  end
  def download([url|urls], host, port, username, password,number,nvrid,channel) do
  #  IO.inspect(urls)
    number=number+1
    IO.inspect("loop #{number}")
    lis = tl(String.split("#{url}" ,~r/rtsp:\/\/\b[0-9]{1,3}.\b[0-9]{1,3}.\b[0-9]{1,3}.\b[0-9]{1,3}/))
    #IO.inspect(lis)
     download_stream("#{host}",  "#{port}",  "#{username}", "#{password}","#{lis}",number,nvrid,channel)
  #:timer.sleep(1000)
     download(urls, host, port, username, password,number,nvrid,channel)

  end
  def download([], host, port, username, password,number,nvrid,channel), do: nil




  def get_stream_urls(_exid, host, port, username, password, channel, starttime, endtime,nvrid) do
    IO.inspect(channel)
if channel== 20 do
   nil
else
    xml = "<?xml version='1.0' encoding='utf-8'?><CMSearchDescription><searchID>C5954E12-60B0-0001-954E-999096EF7420</searchID><trackList>"
      xml = "#{xml}<trackID>#{channel}01</trackID></trackList><timeSpanList><timeSpan><contentTypeList><contentType>video</contentType>
</contentTypeList><startTime>#{starttime}</startTime><endTime>#{endtime}</endTime>"
 xml = "#{xml}</timeSpan></timeSpanList><maxResults>600</maxResults><searchResultPostion>550</searchResultPostion><metadataList>"
    xml = "#{xml}<metadataDescriptor>//metadata.psia.org/VideoMotion</metadataDescriptor></metadataList></CMSearchDescription>"

    url = "http://#{host}:#{port}/ISAPI/ContentMgmt/search"
    case HTTPoison.post(url, xml, ["Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic #{Base.encode64("#{username}:#{password}")}", "SOAPAction": "http://www.w3.org/2003/05/soap-envelope"]) do
      {:ok, %HTTPoison.Response{body: body}} -> {:ok, body}
      { doc, _ } = body |> :binary.bin_to_list |> :xmerl_scan.string
      #[ playbackURI ] = :xmerl_xpath.string('/html/head/title', doc)
    #  IO.inspect(body)
    #result = body |> xpath(~x"//matchup/name/text()") # `sigil_x` for (x)path
  #  IO.inspect(body )
    #IO.inspect(body  |>  SweetXml.xpath(~x"//playbackURI/text()"l))
uri= body  |> SweetXml.xpath(~x"//playbackURI/text()")

    #IO.inspect(  String.split("#{uri}" ,~r/rtsp:\/\/[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}/)   )
#lis = String.split("rtsp://192.168.1.200/Streaming/tracks/301/?starttime=20180728T220252Z&endtime=20180728T223107Z&name=00000002964000000&size=1064787540" ,~r/rtsp:\/\/\b[0-9]{1,3}.\b[0-9]{1,3}.\b[0-9]{1,3}.\b[0-9]{1,3}/)
  #IO.puts(tl(lis))
      download(body  |>  SweetXml.xpath(~x"//playbackURI/text()"l),host, port, username, password,0,nvrid,channel)
    #IO.inspect(body  |>  SweetXml.xpath(~x"//playbackURI/text()"l))
      _ ->

        Logger.error "[get_stream_urls] [#{url}] [#{xml}]"
        {:error}
    end
    get_stream_urls(_exid, host, port, username, password, (channel+1), starttime, endtime,nvrid)

  end

end
  def download_stream(host, port, username, password, url,number,nvrid,channel) do
      xml = "<?xml version='1.0'?><downloadRequest version='1.0' xmlns='http://urn:selfextension:psiaext-ver10-xsd'>"
      xml = "#{xml}<playbackURI>rtsp://#{host}:#{port}#{url}"
      xml = "#{xml}</playbackURI></downloadRequest>"
      root_dir="~"
      path = "#{root_dir}/nvr1/stream#{number}.mkv"
    #  File.rm(path)
      url = "http://#{host}:#{port}/PSIA/Custom/SelfExt/ContentMgmt/download"
      opts = [stream_to: self()]
      HTTPoison.post(url, xml, ["Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic #{Base.encode64("#{username}:#{password}")}", "SOAPAction": "http://www.w3.org/2003/05/soap-envelope"], opts)
      |> collect_response(self(), <<>>,number,nvrid,channel)
    end
    def collect_response(id, par, data,number,nvrid,channel) do
       receive do
         %HTTPoison.AsyncStatus{code: 200, id: id} ->
           Logger.debug "Collect response status"
           collect_response(id, par, data,number,nvrid,channel)
         %HTTPoison.AsyncHeaders{headers: _headers, id: id} ->
           Logger.debug "Collect response headers"
           collect_response(id, par, data,number,nvrid,channel)
         %HTTPoison.AsyncChunk{chunk: chunk, id: id,} ->
           save_temporary(chunk,number,nvrid,channel)
           collect_response(id, par, data,number,nvrid,channel) # <> chunk
         %HTTPoison.AsyncEnd{id: _id} ->
           Logger.debug "Stream complete"
         _ ->
           Logger.debug "Unknown message in response"
           collect_response(id, par, data,number,nvrid,channel)
       after
         5000 ->
           Logger.debug "No response after 5 seconds."
       end
     end
     defp save_temporary(chunk,number,nvrid,channel) do
       root_dir="/home/javi "
       #root_dir="/home/storage-server"

   "#{root_dir}/#{nvrid}/#{channel}/stream#{number}.mkv"
   |> File.open([:append, :binary, :raw], fn(file) -> IO.binwrite(file, chunk) end)
   |> case do
     {:error, :enoent} ->
       File.mkdir_p!("#{root_dir}/#{nvrid}/#{channel}/")
       save_temporary(chunk,number,nvrid,channel)
     _ -> :noop
   end
  end

end
