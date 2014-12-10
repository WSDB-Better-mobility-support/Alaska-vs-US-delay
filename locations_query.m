function [response , delay , error] =  locations_query...
    (request_type, latitude, longitude,height,agl, key_counter, my_path)
%%
error=false; %Default error value
delay=[]; %Default delay value

server_name='https://www.googleapis.com/rpc';
text_coding='"Content-Type: application/json ; charset=utf-8; "';
device_type='"MODE_2"'; %Types of TVWS device: http://en.wikipedia.org/wiki/TV-band_device
if key_counter < 999
    key='"AIzaSyBw4Pt8NYYIwRo-9GHsMWbqzlWVLO90_5c"';%API selection
elseif key_counter < 1999
        key='"AIzaSyAl9rewC1BA-FQyu3iN5xb06_7d9eiiArU"';
else
        key='"AIzaSyBE-GOIVm2-uhWKeB1oINpmoSeyl7dUi3A"'
end


%%
query_generator(request_type,device_type,latitude ,...
    longitude ,height,agl,key, my_path)

%my_path=regexprep(my_path,' ','\\ ');
cmnd=['/usr/bin/curl -X POST   ',server_name,' -H ',text_coding,' --data-binary @',my_path,'/google/google.json -w %{time_total}'];
%cmnd=['/usr/bin/curl -X POST  ',server_name,' -v -i -H "accept-encoding: gzip" ',text_coding,' --data-binary @',my_path,'/google.json -w %{time_total}'];
[status,response]=system(cmnd);

warning_google='Daily Limit Exceeded'; %Error handling in case of exceeed API limit

if ~isempty(findstr(response,warning_google));
    fprintf('API limit exceeded - quitting.\n');
    return;
else
    end_query_str='"FccTvBandWhiteSpace-2010"';
    begining = findstr('{' ,response);
    response = response(begining(1):end);
    disp(response)
    pos_end_query_str=findstr(response,end_query_str);
    % This number needs to be change with number of locations
    pos_end_query_str = pos_end_query_str(end);
   
    length_end_query_str=length(end_query_str)+14; %Note: constant 14 added due to padding of '}' in JSON response
    delay=  str2num(response(pos_end_query_str+length_end_query_str:end));
    response(pos_end_query_str+length_end_query_str:end)=[];
end
system('rm google.json');

end

function  query_generator(request_type,device_type,latitude ,...
    longitude,height,agl,key, my_path)

 cd([my_path,'/google']);

    request=['{"jsonrpc": "2.0",',...
        '"method": "spectrum.paws.getSpectrum",',...
        '"apiVersion": "v1explorer",',...
        '"params": {',...
        '"type": ',request_type,', ',...
        '"version": "1.0", ',...
        '"deviceDesc": ',...
        '{ "serialNumber": "your_serial_number", ',...
        '"fccId": "TEST", ',... %21 June 2014: fix to FCC's "OPSXX ids" case: replace "OPS13" with "TEST" [https://groups.google.com/forum/#!topic/google-spectrum-db-discuss/qitm_hgbw4A]
        '"fccTvbdDeviceType": ',device_type,' }, ',...
        '"location": ',...
        '{ "point": ',...
        '{ "center": ',...
        '{"latitude": ',num2str(latitude),', '...
        '"longitude": ',num2str(longitude),'} } },',...
        '"antenna": ',...
        '{ "height": ',num2str(height),', ',...
        '"heightType": ',agl,' },',...
        '"owner": { "owner": { } }, ',...
        '"capabilities": { "frequencyRanges": [{ "startHz": 800000000, "stopHz": 850000000 }, { "startHz": 900000000, "stopHz": 950000000 }] }, ',...
        '"key": ',key,...
        '},"id": "any_string"}'];

    dlmwrite('google.json',request,'');

end
