% add longitude and latitude to long_lat.txt file. 
% The script will pick random longitude and latitude from the file and do
% the calculations 
% The output will be in a file called Results.txt and a figure will be
% generated
tic; 
clear all; 
close all; 
clc;
%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/Gproject/workspace/data/WSDB_DATA';
%%
%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height= 30.0; %In meters; Note: 'height' needs decimal value
agl='"AMSL"';
num_of_steps = 50; % will be increased inside the for loop
key_counter = 0;
%%
    %The data stored in the file as Alaska long lat us long lat 
    format long;
    long_lat = load('long_lat.txt');
    [r ,c] = size(long_lat);
    ind1 = 0;
    ind2 = 0 ; 
    while ind1 == ind2
        % one number for start one for end 
        % using the while loop to make sure that the two numbers are
        % different
        ind1 = randi(r , 1,1);
        ind2 = randi(r , 1,1);
    end
    longsa = long_lat(ind1, 1);
    latsa = long_lat(ind1, 2);
    longea = long_lat(ind2, 1);
    latea = long_lat(ind2, 2);
    %Alaska Location data    
    long_start_alaska= longsa; 
    lat_start_alaska=latsa ;
    long_end_alaska= longea ;
    lat_end_alaska=latea;
    [long_alaska, lat_alaska] = vector_of_long_lat(long_start_alaska,long_end_alaska,lat_start_alaska,lat_end_alaska,num_of_steps );
    %US Location data

    longsu = long_lat(ind1, 3);
    latsu = long_lat(ind1, 4);
    longeu = long_lat(ind2, 3);
    lateu = long_lat(ind2, 4);
    
    long_start_us= longsu;  
    lat_start_us=latsu ;
    long_end_us= longeu;
    lat_end_us=lateu;
    [long_us, lat_us] = vector_of_long_lat(long_start_us,long_end_us,lat_start_us,lat_end_us,num_of_steps );

    %collect the delay 
    delay_google_alaska=[];
    delay_google_us=[];
    delay_ser = [];
    delay_temp_alaska=[];
    delay_temp_us=[];
    ser_temp_delay = [];

    for i = 1:num_of_steps
            for j = 1:20
                %We need this counter to switch keys once we reachedf 1000
                %or a multiple of it
                key_counter = key_counter + 1 ;
                 cd([my_path,'/google']);
                 
                [~,delay_google_tmp,~]=...
                    locations_query(type,lat_alaska(i) ,long_alaska(i),height,agl,key_counter, my_path );
                delay_temp_alaska = [delay_temp_alaska  delay_google_tmp];
                
                key_counter = key_counter + 1 ;
                
                [~,delay_google_tmp,~]=...
                    locations_query(type,lat_us(i) ,long_us(i),height,agl,key_counter, my_path );
                delay_temp_us = [delay_temp_us  delay_google_tmp];
                
                ser_del =connect_webserver
                ser_temp_delay = [ser_temp_delay ser_del]
                
            end 

            %Get the average of the delay of the same queried area
            delay_alaska = sum(delay_temp_alaska)/length(delay_temp_alaska);
            delay_us = sum(delay_temp_us)/length(delay_temp_us);
            delay_s = sum(ser_temp_delay)/length(ser_temp_delay);
            %collecting the averaged delay 
            delay_google_alaska = [delay_google_alaska delay_alaska];
            delay_google_us = [delay_google_us delay_us];
            delay_ser = [delay_ser delay_s]
            
            % average server delay 
           
            
            delay_temp_alaska = [] ;
            delay_temp_us = [] ;
            ser_temp_delay = [];
            
            delay_alaska = [] ;
            delay_us = [] ;
            delay_s = [] ;
    end
    
    %%
            plot(1:num_of_steps , delay_google_alaska ,'-*' ,...
                1:num_of_steps , delay_google_us,'-^',...
                1:num_of_steps , delay_ser,...
                '-o' ,'LineWidth' , 1 );
            xlabel('Locations number');
            ylabel('Delay (sec)');  
            legend('Alaska' , 'Rest or US', 'Server');

            ave_delay_alaska = sum(delay_google_alaska)/length(delay_google_alaska);
            ave_delay_us = sum(delay_google_us)/length(delay_google_us);
            ave_delay_ser = sum(delay_ser)/length(delay_ser);
            
           fid = fopen('Results.txt' , 'w');
        
           fprintf(fid , 'Average delay in Alaska : %.3f\n' , ave_delay_alaska );
           fprintf(fid, 'Average delay in rest of US : %.3f\n' , ave_delay_us );
           fprintf(fid ,'Average delay of server : %.3f\n' , ave_delay_ser );
           
           fprintf(fid, 'standard deviation of delay in Alaska : %.3f\n' , std(delay_google_alaska) );
           fprintf(fid, 'standard deviation of delay in rest of US : %.3f\n' , std(delay_google_us) );
           fprintf(fid ,'standard deviation of delay of server : %.3f\n' , std(delay_ser) );
           
           fclose(fid);
           
           
            
%%
['Elapsed time: ',num2str(toc/60),' min']