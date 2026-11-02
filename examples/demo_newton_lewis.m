% Synthetic illustration of the analytical drying model (not experimental data).
t=linspace(0,200,201)';A=2.44;k=[.01,.02,.04];
L=A*(-expm1(-t*k));plot(t,L,'LineWidth',1.5);grid on;
xlabel('Time (min)');ylabel('Cumulative water loss (kg)');
legend('k=0.01','k=0.02','k=0.04','Location','best');
fprintf('90%% removal times (min): %s\n',mat2str(log(10)./k,5));
