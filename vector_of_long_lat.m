function [ long , lat ] = vector_of_long_lat( start_long , end_long , start_lat , end_lat , divider )
%This function returns a vector of longitude and latitude
%Calling format :  vector_of_long_lat( start_long , end_long , start_lat , end_lat , divider )
long = linspace(start_long,end_long , divider);
lat = linspace(start_lat,end_lat , divider);


end

