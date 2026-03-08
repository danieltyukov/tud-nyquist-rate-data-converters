% ee315
% homework 2 dac problem starter file
clear all;

savedir = fileparts(mfilename('fullpath'));

% Force light color scheme
try
    s = settings;
    s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';
catch
end
set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesColor', 'w');
set(0, 'DefaultAxesXColor', 'k');
set(0, 'DefaultAxesYColor', 'k');
set(0, 'DefaultTextColor', 'k');

% design choices
% From Problem 3(a)(i): minimum area design
Bt=3;             % Bt bits in thermometer section
Aunit=140;        % Unit element area in um^2 (adjusted for 95% yield)

% fixed parameters
B=12;         % B bits total resolution
Bb=B-Bt;      % Bb bits binary weighted section
dnlspec=0.5;  % DNL specification
inlspec=0.5;  % INL specification
r=100;        % Number of Monte Carlo runs
ku=6e-2;      % Matching parameter (%-um)

% create random unit elements and break up into thermometer and binary weighted array
% mean=1, standard deviation = ku/sqrt(Aunit)
sigma = ku/sqrt(Aunit);
u= sigma*randn(r, 2^B-1) + 1;
u_bw= u(:, 1:2^Bb-1);
u_th= u(:, 2^Bb:end);

% for the bw array, construct a switch matrix of the form
% MSB.....LSB
%[ ... 000
%  ... 001
%  ... 010
%  ... 011
%  ... 100
%  ... ...]

bsm = zeros(2^Bb, Bb);
for i=1:2^Bb
    for j=1:Bb
      if mod( floor((i-1)/2^(j-1)) ,2)
        bsm(i,end-j+1)=1;
       end
    end
end


% create r transfer functions
for m=1:r
  % assemble binary weights and binary array output codes
  bw = zeros(Bb,1);
  for i=1:Bb
    bw(end-i+1) = sum( u_bw(m, 2^(i-1):2^i-1) );
  end
  bw_codes= bsm*bw;

  % assemble output
  for i=1:2^B
    lsb = bw_codes( mod(i-1, 2^Bb)+1 );
    msbs_on = floor((i-1)/2^Bb);
    if msbs_on
      msb = sum( u_th(m,1:2^Bb*msbs_on) );
    else
      msb=0;
    end
    code(m, i) = lsb + msb;
  end
end;


% caculate inl
for m=1:r
  avg_width = (code(m, end)-code(m, 1))/(2^B-1);
  inl(m, :)=(code(m,:)-avg_width*[0:2^B-1])./avg_width;
end

% inl scatter plot
figure(1); clf; hold on;
xlabel('Code');
ylabel('INL [LSB]');
axis([0 2^B-1 -(inlspec+0.05) (inlspec+0.05)]);
line([0 2^B-1], [inlspec inlspec], 'Color', 'r', 'LineWidth', 1.5);
line([0 2^B-1], [-inlspec -inlspec], 'Color', 'r', 'LineWidth', 1.5);

bad_dacs_inl=0;
for m=1:r
  figure(1);
  plot(0:2^B-1, inl(m,:));
  if find(abs(inl(m,:))>inlspec)
      bad_dacs_inl=bad_dacs_inl+1;
  end
end

figure(1); hold off;
title( sprintf('INL envelope of %d runs. %d bad DAC(s). (B_t=%d, A_{unit}=%.2f\\mum^2)', r, bad_dacs_inl, Bt, Aunit));
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
exportgraphics(gcf, fullfile(savedir, sprintf('p4b_inl_envelope_A%.0f.png', Aunit)), 'BackgroundColor', 'white', 'Resolution', 150);

% inl rms plot
inl_rms = sqrt(sum( inl.^2, 1 ) ./r);
[maxinlrms imax] = max(inl_rms);
figure(2); clf;
plot(0:2^B-1, inl_rms, imax-1, maxinlrms, 'r*', 'MarkerSize', 10);
xlabel('Code');
ylabel('INL [LSB]');
title( sprintf('RMS INL of %d runs. (max=%1.3fLSBrms)', r, maxinlrms));
axis([0 2^B-1 0 maxinlrms+0.01]);
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
exportgraphics(gcf, fullfile(savedir, sprintf('p4b_inl_rms_A%.0f.png', Aunit)), 'BackgroundColor', 'white', 'Resolution', 150);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Your code goes here

%   calculate dnl
for m=1:r
  avg_width = (code(m, end)-code(m, 1))/(2^B-1);
  % DNL(k) = [W(k+1) - W(k)] / avg_width - 1
  % where W(k) = code(m, k) is the actual output at code k
  dnl(m, :) = diff(code(m,:)) ./ avg_width - 1;
end

%   dnl scatter plot
figure(3); clf; hold on;
xlabel('Code');
ylabel('DNL [LSB]');
axis([0 2^B-2 -(dnlspec+0.05) (dnlspec+0.05)]);
line([0 2^B-2], [dnlspec dnlspec], 'Color', 'r', 'LineWidth', 1.5);
line([0 2^B-2], [-dnlspec -dnlspec], 'Color', 'r', 'LineWidth', 1.5);

bad_dacs_dnl=0;
for m=1:r
  figure(3);
  plot(0:2^B-2, dnl(m,:));
  if find(abs(dnl(m,:))>dnlspec)
      bad_dacs_dnl=bad_dacs_dnl+1;
  end
end

figure(3); hold off;
title( sprintf('DNL envelope of %d runs. %d bad DAC(s). (B_t=%d, A_{unit}=%.2f\\mum^2)', r, bad_dacs_dnl, Bt, Aunit));
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
exportgraphics(gcf, fullfile(savedir, sprintf('p4b_dnl_envelope_A%.0f.png', Aunit)), 'BackgroundColor', 'white', 'Resolution', 150);

%   dnl rms plot
dnl_rms = sqrt(sum( dnl.^2, 1 ) ./r);
[maxdnlrms, dmax] = max(dnl_rms);
figure(4); clf;
plot(0:2^B-2, dnl_rms, dmax-1, maxdnlrms, 'r*', 'MarkerSize', 10);
xlabel('Code');
ylabel('DNL [LSB]');
title( sprintf('RMS DNL of %d runs. (max=%1.3fLSBrms)', r, maxdnlrms));
axis([0 2^B-2 0 maxdnlrms+0.01]);
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
exportgraphics(gcf, fullfile(savedir, sprintf('p4b_dnl_rms_A%.0f.png', Aunit)), 'BackgroundColor', 'white', 'Resolution', 150);

%% Print yield summary
fprintf('\n=== YIELD SUMMARY (Bt=%d, Aunit=%.2f um^2) ===\n', Bt, Aunit);
fprintf('sigma_u = %.6f\n', sigma);
fprintf('Bad DACs (INL): %d / %d\n', bad_dacs_inl, r);
fprintf('Bad DACs (DNL): %d / %d\n', bad_dacs_dnl, r);
bad_total = 0;
for m=1:r
    if any(abs(inl(m,:))>inlspec) || any(abs(dnl(m,:))>dnlspec)
        bad_total = bad_total + 1;
    end
end
fprintf('Bad DACs (either): %d / %d\n', bad_total, r);
fprintf('Yield: %.1f%%\n', (r - bad_total)/r * 100);
fprintf('Target yield: 95%% (max 5 bad out of %d)\n', r);

if bad_total > 5
    fprintf('\n*** YIELD NOT MET — need to increase Aunit ***\n');
else
    fprintf('\n*** YIELD MET ***\n');
end
