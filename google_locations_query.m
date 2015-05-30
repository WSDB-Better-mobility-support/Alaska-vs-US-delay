
% google_location_query compare the response time of querying google WSDB
% in Alaska and the rest of the US
% add longitude and latitude to long_lat.txt file.
% The script will pick random longitude and latitude from the file and do
% the calculations
% The output will be in a file called Results.txt and a figure will be
% generated

%   Last update: 12 January 2015

% Reference:
%   P. Pawelczak et al. (2014), "Will Dynamic Spectrum Access Drain my
%   Battery?," submitted for publication.

%   Code development: Amjed Yousef Majid (amjadyousefmajid@student.tudelft.nl),
%                     Przemyslaw Pawelczak (p.pawelczak@tudelft.nl)

% Copyright (c) 2014, Embedded Software Group, Delft University of
% Technology, The Netherlands. All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
% contributors may be used to endorse or promote products derived from this
% software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

tic;
clear;
close all;
clc;
%%
%Plot parameters
fontSize=16;
lineWidth=1.5;
x_start =-0.03;
x_end = 0.83;
box_width = 0.2;
box1_pos = 0.1;
box2_pos = 0.4;
box3_pos = 0.7;
outlierSize = 3;
%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/Gproject/workspace/data/WSDB_DATA';
%%
%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height= 30.0; %In meters; Note: 'height' needs decimal value
agl='"AGL"';
num_of_steps = 49; % will be increased inside the for loop
num_of_query_per_location = 20 ;
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
    for j = 1:num_of_query_per_location
        %We need this counter to switch keys once we reachedf 1000
        %or a multiple of it
        key_counter = key_counter + 1 ;
        cd(my_path);
        
        [~,delay_google_tmp,error1]=...
            locations_query(type,lat_alaska(i) ,long_alaska(i),height,agl,key_counter, my_path );
        if error1 ==0
            delay_temp_alaska = [delay_temp_alaska  delay_google_tmp];
        end
        key_counter = key_counter + 1 ;
        
        [~,delay_google_tmp,error2]=...
            locations_query(type,lat_us(i) ,long_us(i),height,agl,key_counter, my_path );
        if error2 ==0
            delay_temp_us = [delay_temp_us  delay_google_tmp];
        end
        ser_del =connect_webserver;
        ser_temp_delay = [ser_temp_delay ser_del];
        
    end
    if error1 == 0 && error2 == 0
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
end

%%
% plot and Boxplot
figure('Position',[440 378 560 620/3]);
d = [delay_google_alaska' ,delay_google_us', delay_ser'];
boxplot( d, 'notch','on','widths',[box_width box_width box_width ],...
    'outliersize',outlierSize,'positions', [box1_pos box2_pos box3_pos],'factorseparator',1);

ylabel('Delay (sec)');
set(gca , 'XTickLabel',{'Tuvak-Bethel (AK)' , 'Fertile-Hobbs (US)', 'Googleapis (rpc)'});
set(findobj(gca,'type','line'),'linew',lineWidth);
ax = gca;
ax.YTick = [0:0.5:2];
xlim([x_start x_end])
ylim([0 2]);
set(gca, 'fontsize', fontSize)

figure('Position',[440 378 560 620/3]);
plot(1:num_of_steps , delay_google_alaska ,'-*' ,...
    1:num_of_steps , delay_google_us,'-^',...
    1:num_of_steps , delay_ser,...
    '-o' ,'LineWidth' , 1 );
xlabel('Locations number');
ylabel('Delay (sec)');
legend({'AK' , 'US', 'rpc'});
%legend({'Tuvak-Bethel (AK)' , 'Fertile-Hobbs (US)', 'Googleapis (rpc)'});
set(findobj('type','axes') , 'FontSize',fontSize);
set(findobj('type','text'),'FontSize',fontSize);
set(findobj(gca,'type','line'),'linew',lineWidth);
xlim([1 num_of_steps])
yMax = max([max(delay_google_alaska),max(delay_google_us), max(delay_ser)]);
ylim([0 yMax]);
ax = gca;
ax.YTick = [0:1:yMax];
%%
%save
save('Alaska-US-delay-comparison')
%%
%Statistics
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