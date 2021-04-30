% Abe Jordan
% ECE 477
% Lab 7

%% Clear workspace
clear workspace;
clear variables;
clc;

%% take average of control temperatures
data0_values = importdata('adc_values_0c.csv');
data19_values = importdata('adc_values_19c.csv');
datat_values = importdata('adc_values_t.csv');
datan18_values = datat_values((length(datat_values)-178):length(datat_values));

data0_average = mean(data0_values);
data19_average = mean(data19_values);
datan18_average = mean(datan18_values);

data0_sum = sum(data0_values);
data19_sum = sum(data19_values);
datan18_sum = sum(datan18_values);

data0_median = median(sort(data0_values));
data19_median = median(sort(data19_values));
datan18_median = median(sort(datan18_values));

res1 = abs((data0_median - data19_median)/(0 - 19));
res2 = abs((data0_median - datan18_median)/(0 - -18));
res3 = abs((data19_median - datan18_median)/(19 - 18));
res_avg = mean([res1 res2 res3]);

fprintf("0 C - Sum: %d, Avg: %f, Med: %d\n",data0_sum,data0_average,data0_median);
fprintf("19 C - Sum: %d, Avg: %f, Med: %d\n",data19_sum,data19_average,data19_median);
fprintf("-18 C - Sum: %d, Avg: %f, Med: %d\n",datan18_sum,datan18_average,datan18_median);
fprintf("Resolution:\nIce & Ambient: %d (%f mV/C)\n",res1,res1*1100/1024)
fprintf("Ice & Salted Ice: %d (%f mV/C)\n",res2,res2*1100/1024)
fprintf("Ambient & Salted Ice: %d (%f mV/C)\n",res3,res3*1100/1024)
fprintf("Average: %d (%f mV/C)\n",res_avg,res_avg*1100/1024)

%% plot samples
figure('name','ece 477 lab 7 data');
scatter(0:(length(data0_values)-1),data0_values,'filled');
hold on;
scatter(0:(length(data19_values)-1),data19_values,'filled');
hold on;
scatter(0:(length(datan18_values)-1),datan18_values,'filled');
xlabel('Sample');
ylabel('ADC Value')
xlim([0 150]);
ylim([310 360]);
grid on;
legend('Ice (0 ^oC)','Ambient (19 ^oC)','Salted Ice (-18 ^oC)');

p = polyfit(0:(length(datat_values)-1),datat_values,1);
t = linspace(0,(length(datat_values)-1),length(datat_values));

figure('name','ece 477 lab 7 data 2');
scatter(t/2,movmean(datat_values,10));
hold on;
plot(t/2,p(1)*t+p(2),'linewidth',2);
xlabel('Time (Seconds)');
ylabel('ADC Value');
xlim([0 150]);
ylim([300 350]);
grid on;
legend('Raw Data','Fitted Line');

res_fit = abs(-159*p(1))/(19 - -18);
fprintf("Fitted Data Resolution: %d (%f mV/C)\n",res_fit,res_fit*1100/1024);

%% distribute data
bin_min0=10*floor(min(data0_values)/10);
bin_max0=10*ceil(max(data0_values)/10);
bin_div0 = floor((bin_max0-bin_min0))+1;
bins0 = linspace(bin_min0,bin_max0,bin_div0);

bin_min19=10*floor(min(data19_values)/10);
bin_max19=10*ceil(max(data19_values)/10);
bin_div19 = floor((bin_max19-bin_min19))+1;
bins19 = linspace(bin_min19,bin_max19,bin_div19);

bin_minn18=10*floor(min(datan18_values)/10);
bin_maxn18=10*ceil(max(datan18_values)/10);
bin_divn18 = floor((bin_maxn18-bin_minn18))+1;
binsn18 = linspace(bin_minn18,bin_maxn18,bin_divn18);

wlength0 = max(data0_values)-min(data0_values);
wlength19 = max(data19_values)-min(data19_values);
wlengthn18 = max(datan18_values)-min(datan18_values);
wlength = max(wlength0,max(wlength19,wlengthn18));

figure('name','ece 477 lab 7 0 degrees');
histogram(data0_values,bins0);
xlabel('ADC Value');
ylabel('Count');
xlim([min(data0_values)-1 min(data0_values)+wlength+2]);
ylim([0 50]);
grid on;

figure('name','ece 477 lab 7 19 degrees');
histogram(data19_values,bins19);
xlabel('ADC Value');
ylabel('Count');
xlim([min(data19_values)-1 min(data19_values)+wlength+2]);
ylim([0 50]);
grid on;

figure('name','ece 477 lab 7 -18 degrees');
histogram(datan18_values,binsn18);
xlabel('ADC Value');
ylabel('Count');
xlim([min(datan18_values)-1 min(datan18_values)+wlength+2]);
ylim([0 50]);
grid on;

%% fit datasheet data
syms tos1_ds k1_ds;
[tos1_ds,k1_ds] = solve((292-tos1_ds)/k1_ds == 25, (354-tos1_ds)/k1_ds == 85, tos1_ds, k1_ds);
fprintf("Using data sheet (25 C & 85 C) - toff: %f, k %f\n",tos1_ds,k1_ds);

syms tos2_ds k2_ds;
[tos2_ds,k2_ds] = solve((292-tos2_ds)/k2_ds == 25, (225-tos2_ds)/k2_ds == -45, tos2_ds, k2_ds);
fprintf("Using data sheet (25 C & -45 C) - toff: %f, k %f\n", tos2_ds, k2_ds);

syms tos3_ds k3_ds;
[tos3_ds,k3_ds] = solve((354-tos3_ds)/k3_ds == 85, (225-tos3_ds)/k3_ds == -45, tos3_ds, k3_ds);
fprintf("Using data sheet (85 C & -45 C) - toff: %f, k %f\n",tos3_ds, k3_ds);

tos_ds = mean([tos1_ds tos2_ds tos3_ds]);
k_ds = mean([k1_ds k2_ds k3_ds]);

fprintf("Using data sheet (Average) - toff: %f, k %f\n",tos_ds,k_ds);

%% fit experimental data
syms tos1_exp k1_exp;
[tos1_exp,k1_exp] = solve((data0_median-tos1_exp)/k1_exp == 0, (data19_median-tos1_exp)/k1_exp == 19, tos1_exp, k1_exp);
fprintf("Using experimental data (0 C & 19 C) - toff: %f, k %f\n",tos1_exp,k1_exp);

syms tos2_exp k2_exp;
[tos2_exp,k2_exp] = solve((data0_median-tos2_exp)/k2_exp == 0, (datan18_median-tos2_exp)/k2_exp == -18, tos2_exp, k2_exp);
fprintf("Using experimental data (0 C & -18 C) - toff: %f, k %f\n", tos2_exp, k2_exp);

syms tos3_exp k3_exp;
[tos3_exp,k3_exp] = solve((data19_median-tos3_exp)/k3_exp == 19, (datan18_median-tos3_exp)/k3_exp == -18, tos3_exp, k3_exp);
fprintf("Using experimental data (19 C & -18 C) - toff: %f, k %f\n",tos3_exp, k3_exp);

tos_exp = mean([tos1_exp tos2_exp tos3_exp]);
k_exp = mean([k1_exp k2_exp k3_exp]);

fprintf("Using experimental data (Average) - toff: %f, k %f\n",tos_exp,k_exp);

%% plot trendlines
adc = linspace(0,1023,1024);
figure('name','temperature vs adc value');
plot(adc,(adc-tos_ds)/k_ds,...
     adc,(adc-tos1_ds)/k1_ds,'--',...
     adc,(adc-tos2_ds)/k2_ds,'--',...
     adc,(adc-tos3_ds)/k3_ds,'--',...
     adc,(adc-tos_exp)/k_exp,...
     adc,(adc-tos1_exp)/k1_exp,'--',...
     adc,(adc-tos2_exp)/k2_exp,'--',...
     adc,(adc-tos3_exp)/k3_exp,'--');
hold on;
scatter(datan18_median,-18,'filled');
scatter(data19_median,19,'filled');
scatter(data0_median,0,'filled');
grid on;
xlabel('ADC Value');
ylabel('Temperature (^oC)');
legend('Data Sheet (Average)',...
       'Data Sheet (25 ^oC & 85 ^oC)',...
       'Data Sheet (25 ^oC & -45 ^oC)',...
       'Data Sheet (-45 ^oC & 85 ^oC)',...
       'Experimental Fit (Average)',...
       'Experimental Fit (Ice & Ambient)',...
       'Experimental Fit (Ice & Salted Ice)',...
       'Experimental Fit (Ambient & Salted Ice)',...
       'Salted Ice (-18 ^oC)',...
       'Ambient (19 ^oC)',...
       'Ice (0 ^oC)',...
       'location','northwest');
xlim([200 450]);

figure('name','temperature vs vin');
plot(adc*1100/1024,(adc-tos_ds)/k_ds,...
     adc*1100/1024,(adc-tos1_ds)/k1_ds,'--',...
     adc*1100/1024,(adc-tos2_ds)/k2_ds,'--',...
     adc*1100/1024,(adc-tos3_ds)/k3_ds,'--',...
     adc*1100/1024,(adc-tos_exp)/k_exp,...
     adc*1100/1024,(adc-tos1_exp)/k1_exp,'--',...
     adc*1100/1024,(adc-tos2_exp)/k2_exp,'--',...
     adc*1100/1024,(adc-tos3_exp)/k3_exp,'--');
hold on;
scatter(datan18_median*1100/1024,-18,'filled');
scatter(data19_median*1100/1024,19,'filled');
scatter(data0_median*1100/1024,0,'filled');
grid on;
xlabel('ADC Input Voltage (mV)');
ylabel('Temperature (^oC)');
legend('Data Sheet (Average)',...
       'Data Sheet (25 ^oC & 85 ^oC)',...
       'Data Sheet (25 ^oC & -45 ^oC)',...
       'Data Sheet (-45 ^oC & 85 ^oC)',...
       'Experimental Fit (Average)',...
       'Experimental Fit (Ice & Ambient)',...
       'Experimental Fit (Ice & Salted Ice)',...
       'Experimental Fit (Ambient & Salted Ice)',...
       'Salted Ice (-18 ^oC)',...
       'Ambient (19 ^oC)',...
       'Ice (0 ^oC)',...
       'location','northwest');
xlim([210 500]);