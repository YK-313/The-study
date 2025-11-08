figure(2)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

%緑#77AC30  青#0072BD 赤#A2142F

h = semilogy(SIM.ResSi,BER,'-o');


hold on


set(h,'MarkerFaceColor','#A2142F','color','#A2142F');
grid on
lb(1) = xlabel('残留SIの平均電力 (真値)');
lb(2) = ylabel('BER');

axis([min(SIM.ResSi) max(SIM.ResSi) 10^(-5) 10^-1]);

set(gca,'Linewidth',LW,'FontName',FN,'FontSize',FS,'ytick',10.^[-5:1:-1],'PlotBoxAspectRatio',[1 1 1]);
set(lb,'FontName',FN,'FontSize',FS);
set(h,'Linewidth',LW,'MarkerSize',MS);