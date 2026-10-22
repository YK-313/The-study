figure(2)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

%óŒ#77AC30  ê¬#0072BD ê‘#A2142F

h = semilogy(SIM.SNR,BER,'-o');


hold on


set(h,'MarkerFaceColor','#A2142F','color','#A2142F');
grid on
lb(1) = xlabel('SNR [dB]');
lb(2) = ylabel('BER');

axis([min(SIM.SNR) max(SIM.SNR) 10^(-5) 10^0]);

set(gca,'Linewidth',LW,'FontName',FN,'FontSize',FS,'ytick',10.^[-5:1:0],'xTick',[0:5:40],'PlotBoxAspectRatio',[1 1 1]);
set(lb,'FontName',FN,'FontSize',FS);
set(h,'Linewidth',LW,'MarkerSize',MS);