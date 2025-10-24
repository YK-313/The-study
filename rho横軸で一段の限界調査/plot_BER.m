figure(2)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

%óŒ#77AC30  ê¬#0072BD ê‘#A2142F

h = semilogy(SIM.rho,BER,'-o');


hold on


set(h,'MarkerFaceColor','#A2142F','color','#A2142F');
grid on
lb(1) = xlabel('rho [dB]');
lb(2) = ylabel('BER');

axis([min(SIM.rho) max(SIM.rho) 10^(-6) 10^-4]);

set(gca,'Linewidth',LW,'FontName',FN,'FontSize',FS,'ytick',10.^[-6:1:-4],'PlotBoxAspectRatio',[1 1 1]);
set(lb,'FontName',FN,'FontSize',FS);
set(h,'Linewidth',LW,'MarkerSize',MS);