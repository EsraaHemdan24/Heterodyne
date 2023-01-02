%Reading 2 signals and display them
[Signal_1,FS_1] = audioread('C:\Users\User\Desktop\COMMUNICATION PROJECT\Short_BBCArabic2.wav');
%sound(Signal_1,FS_1);
%pause(25);
[Signal_2,FS_2] = audioread('C:\Users\User\Desktop\COMMUNICATION PROJECT\Short_FM9090.wav');
%sound(Signal_2,FS_2);
 
 
%Adding the two columns of both signals to convert them from stereo to
%monophonic signals
Signal_1 = (Signal_1(: , 1)+ Signal_1(: , 2))';
Signal_2 = (Signal_2(: , 1)+ Signal_2(: , 2))';
Signal_1_length = length(Signal_1);
Signal_2_length = length(Signal_2);
 
 
%Zero padding the smaller signal to make both signals have the same size
if (Signal_1_length>Signal_2_length)
    Signal_2=horzcat(Signal_2 , zeros(1,Signal_1_length-Signal_2_length));
    monophonic_signal_length = Signal_1_length;
else
    Signal_1=horzcat(Signal_1 , zeros(1,Signal_2_length-Signal_1_length));
    monophonic_signal_length = Signal_2_length;
end
 
k=(-monophonic_signal_length/2:monophonic_signal_length/2-1);
 
 
%plotting the original signals
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Signal_1))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Original BBCArabic2 Signal');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Signal_2))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Original FM9090 Signal');
 
 
%AM modulator stage
 
%increasing the sampling frequency by factor of 10 to satisfy the Nyquist rate
Signal_1 = interp(Signal_1,10);  %decreased the Ts by 1/10
Signal_2 = interp(Signal_2,10);
monophonic_signal_length = length(Signal_1);   %new length 
FS_1 = FS_1*10;   %increased the Fs by 10
FS_2 = FS_2*10;
 
%new mapping
k=(-monophonic_signal_length/2:monophonic_signal_length/2-1);
 
 
%plotting the signals after increasing the sampling frequency
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Signal_1))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Interpolated BBCArabic2 Signal');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Signal_2))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Interpolated FM9090 Signal');
 
n=0:monophonic_signal_length-1;    %number of samples
Carrier_1_Freq = 100000;
Carrier_2_Freq = 150000;
IF_Freq = 25000;
 
 
%Mixing both signals with carrier (modulation) and add them (FDM)
Modulated_Signal_1 = Signal_1 .* cos(2*pi*n*Carrier_1_Freq*(1/FS_1));  %TS=1/Fs
Modulated_Signal_2 = Signal_2 .* cos(2*pi*n*Carrier_2_Freq*(1/FS_2));
Transmitted_Signal = Modulated_Signal_1 + Modulated_Signal_2;
 
 
%plotting the transmitted signal
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Transmitted_Signal))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Transmitted Signal');
 
 
%now start implementing the RF stage which is our reciever 
%design the band pass filter 
%here the first signal has approximatly bandwidth 44 khz around the carrier
% i.e from (78 khz to 122 khz)
%here the second signal has approximatly bandwidth 44 khz around the carrier
% i.e from (128 khz to 172 khz)
BPF_RF_1 =designfilt('bandpassfir' , 'FilterOrder' , 20 , 'CutoffFrequency1' , 78000 ,'CutoffFrequency2' , 122000 , 'SampleRate' , FS_1 );
BPF_RF_2 =designfilt('bandpassfir' , 'FilterOrder' , 20 , 'CutoffFrequency1' , 128000 ,'CutoffFrequency2' , 172000 , 'SampleRate' , FS_2 );
Recieved_FirstSignal = filtfilt(BPF_RF_1 , Transmitted_Signal );
Recieved_SecondSignal = filtfilt(BPF_RF_2 , Transmitted_Signal );
 
 
% plot the 2 signals after BPF of the RF stage
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Recieved_FirstSignal))));
ylabel ('First Signal Amplitude');
xlabel (' F (HZ)');
title ('BBCArabic2 Signal After RF BPF');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Recieved_SecondSignal))));
ylabel ('Second Signal Amplitude');
xlabel (' F (HZ)');
title ('FM9090 Signal After RF BPF');
 
 
%the sceond step in our RF stage reciver which is implementing our mixer
%i.e bringing our 2 signals to IF frequency
IF_FirstSignal = Recieved_FirstSignal .* cos(2*pi*(Carrier_1_Freq + IF_Freq)*n*(1/FS_1));
IF_SecondSignal = Recieved_SecondSignal .* cos(2*pi*(Carrier_2_Freq + IF_Freq)*n*(1/FS_2));
 
 
%plot the 2 signals after mixing
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(IF_FirstSignal))));
ylabel ('First Signal Amplitude');
xlabel (' F (HZ)');
title ('BBCArabic2 Signal After RF Mixer');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(IF_SecondSignal))));
ylabel ('Second Signal Amplitude');
xlabel (' F (HZ)');
title ('FM9090 Signal After RF Mixer');
 
 
%implementing the IF Stage
%designing the band pass filter of the IF stage
%first signal has approximatly bandwidth 44 khz around the IF frequency
% i.e from (3 khz to 74 khz)
%second signal has approximatly bandwidth 44 khz around the IF frequency
% i.e from (3 khz to 74 khz)
BPF_IF_1 = designfilt('bandpassfir' , 'FilterOrder' , 20 , 'CutoffFrequency1' , 3000 , 'CutoffFrequency2' , 47000 , 'SampleRate' , FS_1 );
BPF_IF_2 = designfilt('bandpassfir' , 'FilterOrder' , 20 , 'CutoffFrequency1' , 3000 , 'CutoffFrequency2' , 47000 , 'SampleRate' , FS_2 );
Demodulated_FirstSignal = filtfilt(BPF_IF_1 , IF_FirstSignal);
Demodulated_SecondSignal = filtfilt(BPF_IF_2 , IF_SecondSignal);
 
 
%plot the 2 signals after filter in the IF Stage
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Demodulated_FirstSignal))));
ylabel ('First Signal Amplitude');
xlabel (' F (HZ)');
title ('BBCArabic2 Signal After IF BPF');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Demodulated_SecondSignal))));
ylabel ('Second Signal Amplitude');
xlabel (' F (HZ)');
title ('FM9090 Signal After IF BPF');
 
 
%implementing the BaseBand Stage
%mix two signals with their corresponding carriers 
%then bringing both signals to the baseband
Mixed_FirstSignal = Demodulated_FirstSignal .* cos(2*pi*IF_Freq*n*(1/FS_1));
Mixed_SecondSignal = Demodulated_SecondSignal .* cos(2*pi*IF_Freq*n*(1/FS_2));
 
 
%plot the 2 signals after mixing and bringing to baseband 
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Mixed_FirstSignal))));
ylabel ('First Signal Amplitude');
xlabel (' F (HZ)');
title ('BBCArabic2 Signal After baseband mixer before (LPF)');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Mixed_SecondSignal))));
ylabel ('Second Signal Amplitude');
xlabel (' F (HZ)');
title ('FM9090 Signal After baseband mixer before (LPF)');
 
 
%designing the Low Pass Filter of the Baseband Stage
%both first and second signals have BW of approximately 18 khz (from -25 khz to 25 khz)
LPF_BaseBand_1 = designfilt('lowpassfir' , 'PassBandFrequency' , 25000 , 'StopBandFrequency' , 27000 , 'SampleRate' , FS_1);
LPF_BaseBand_2 = designfilt('lowpassfir' , 'PassBandFrequency' , 25000 , 'StopBandFrequency' , 27000 , 'SampleRate' , FS_2);
Final_FirstSignal = filtfilt(LPF_BaseBand_1 , Mixed_FirstSignal);
Final_SecondSignal = filtfilt(LPF_BaseBand_1 , Mixed_SecondSignal);
 
 
%plot the 2 signals after baseband LPF 
plot(k*FS_1/monophonic_signal_length , abs(fftshift(fft(Final_FirstSignal))));
ylabel ('First Signal Amplitude');
xlabel (' F (HZ)');
title ('interpolated BBCArabic2 Signal After baseband LPF');
plot(k*FS_2/monophonic_signal_length , abs(fftshift(fft(Final_SecondSignal))));
ylabel ('Second Signal Amplitude');
xlabel (' F (HZ)');
title ('interpolated FM9090 Signal After baseband LPF');
 
 
%multiplying both signals by 4 to get rid of the modulation and demodulation
Final_FirstSignal = 4.* Final_FirstSignal ;
Final_SecondSignal = 4.* Final_SecondSignal ;
 
 
%decreasing the sampling frequency back to its original value
%i.e removing the interp function effect
Final_FirstSignal = Final_FirstSignal(1:10:monophonic_signal_length);
Final_SecondSignal = Final_SecondSignal(1:10:monophonic_signal_length);
FS_1 = FS_1 / 10 ;
FS_2 = FS_2 / 10 ;
Final_FirstSignal_length = length(Final_FirstSignal);
Final_SecondSignal_length = length(Final_SecondSignal);
 
 
%Zero padding the smaller signal to make both signals have the same size
if (Final_FirstSignal_length>Final_SecondSignal_length)
    Final_SecondSignal=horzcat(Final_SecondSignal , zeros(1,Final_FirstSignal_length-Final_SecondSignal_length));
    monophonic2_signal_length = Final_FirstSignal_length;
else
    Final_FirstSignal=horzcat(Final_FirstSignal , zeros(1,Final_SecondSignal_length-Final_FirstSignal_length));
    monophonic2_signal_length = Final_SecondSignal_length;
end
k2=(-monophonic2_signal_length/2:monophonic2_signal_length/2-1);
 
 
%plotting the final signals after demodulation
plot(k2*FS_1/monophonic2_signal_length , abs(fftshift(fft(Final_FirstSignal))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Final BBCArabic2 Signal');
plot(k2*FS_2/monophonic2_signal_length , abs(fftshift(fft(Final_SecondSignal))));
xlabel('Freq (Hz)');
ylabel('Signal Amplitude');
title('Final FM9090 Signal');
 
 
%%%%listening to the 2 signals after modulation to check they work properly
sound(Final_FirstSignal , FS_1);
pause(20);
sound(Final_SecondSignal , FS_2);
