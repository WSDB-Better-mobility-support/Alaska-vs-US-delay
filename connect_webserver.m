function [delay]=connect_webserver

     cmnd=['/usr/bin/curl https://www.googleapis.com/rpc/ -H "Content-Type: application/json; charset=utf-8" -w %{time_total}'];


[status,response]=system(cmnd); %Run command
disp(response)
%Extract delay from a query
end_query_str='}]}}';
pos_end_query_str=findstr(response,end_query_str);
length_end_query_str=length(end_query_str);
delay=str2num(response(pos_end_query_str+length_end_query_str:end));