function run_project
root=fileparts(fileparts(mfilename('fullpath')));out=fullfile(root,'results');figdir=fullfile(root,'figures');
if ~exist(out,'dir'),mkdir(out);end;if ~exist(figdir,'dir'),mkdir(figdir);end
input=fullfile(root,'data','drying_curves.csv');
assert(isfile(input),'Place the authorized dataset at data/drying_curves.csv. See data/README.md.');
X=readmatrix(input,'NumHeaderLines',1);ids=unique(X(:,1));n=numel(ids);m=41;
T=zeros(m,n);F=T;Z=zeros(n,3);A=zeros(n,1);C=A;K=A;dur=A;obs90=nan(n,1); curves=cell(n,1);
for i=1:n
 s=X(X(:,1)==ids(i),:);t=s(:,6);L=s(:,8);A(i)=s(1,11);C(i)=s(1,2);Z(i,:)=s(1,3:5);dur(i)=max(t);curves{i}=s;
 T(:,i)=linspace(0,max(t),m)';F(:,i)=interp1(t,L/A(i),T(:,i));
 f=@(k)mean((-expm1(-k*t)-L/A(i)).^2);K(i)=fminbnd(f,1e-7,.2,optimset('TolX',1e-12));
 j=find(L/A(i)>=.9,1);if ~isempty(j)&&j>1,obs90(i)=t(j-1)+(.9-L(j-1)/A(i))/(L(j)/A(i)-L(j-1)/A(i))*(t(j)-t(j-1));end
end
z=(Z-[60,195.6,27])./[20,84.65,14.85]; levels=unique(C); lambdas=[1e-4,.01,.1];seeds=[17,41,73];pred=zeros(n,4);chosen=zeros(numel(levels),1);models=cell(numel(levels),3);betaall=zeros(4,numel(levels));
for fold=1:numel(levels)
 te=C==levels(fold);tr=~te;inner=mod(C,3);scores=zeros(3,1);
 for q=1:3
  err=[];
  for v=0:2
   train=tr & inner~=v;val=tr & inner==v;
   b=linearfit(z(train,:),T(:,train),F(:,train),K(train));
   p=netfit(z(train,:),T(:,train),F(:,train),b,lambdas(q),17);
   kval=netpredict(p,z(val,:));e=-expm1(-T(:,val).*kval')-F(:,val);err=[err,mean(e.^2,1)];
  end
  scores(q)=mean(err);
 end
 [~,q]=min(scores);chosen(fold)=lambdas(q);
 b=linearfit(z(tr,:),T(:,tr),F(:,tr),K(tr));betaall(:,fold)=b;pred(te,1)=exp([ones(sum(te),1),z(te,:)]*b);
 for rep=1:3
  p=netfit(z(tr,:),T(:,tr),F(:,tr),b,lambdas(q),seeds(rep));models{fold,rep}=p;pred(te,rep+1)=netpredict(p,z(te,:));
 end
 fprintf('LOCO %d/27 condition %d lambda %.4g\n',fold,levels(fold),chosen(fold));
end
R=[];for i=1:n
 s=curves{i};t=s(:,6);L=s(:,8);
 for method=1:4
  k=pred(i,method);ph=A(i)*(-expm1(-k*t));rmse=sqrt(mean((ph-L).^2));mae=mean(abs(ph-L));tp=log(10)/k;
  R=[R;ids(i),C(i),method,k,rmse,mae,tp,obs90(i),tp-obs90(i),(k-K(i))/K(i)*100];
 end
end
names={'operation','condition','method','predicted_k_min_inv','curve_RMSE_g','curve_MAE_g','predicted_t90_min','observed_t90_min','t90_error_min','k_relative_error_percent'};
writetable(array2table(R,'VariableNames',names),fullfile(out,'loco_metrics.csv'));
writetable(array2table([ids,C,Z,A,K,dur,obs90],'VariableNames',{'operation','condition','T_C','G_kg_h','omega_g_kg','Aref_g','fitted_k_min_inv','duration_min','observed_t90_min'}),fullfile(out,'run_parameters.csv'));
writetable(array2table([levels,chosen],'VariableNames',{'condition','selected_lambda'}),fullfile(out,'selected_hyperparameters.csv'));
stats=struct;stats.runs=n;stats.conditions=numel(levels);stats.observations=size(X,1);stats.matlab_version=version;stats.observed_t90_count=sum(isfinite(obs90));stats.hidden_units=4;stats.epochs=1200;stats.seeds=seeds;stats.lambdas=lambdas;
for method=1:4
 r=R(R(:,3)==method,:); st=struct('median_curve_RMSE_g',median(r(:,5)),'mean_curve_RMSE_g',mean(r(:,5)),'median_abs_t90_error_min',median(abs(r(isfinite(r(:,9)),9))),'median_abs_k_error_percent',median(abs(r(:,10))));stats.(['method',num2str(method)])=st;
end
stats.mlp_wins_vs_linear=sum(R(R(:,3)==2,5)<R(R(:,3)==1,5));stats.A_mean_g=mean(A);stats.A_sd_g=std(A);
fid=fopen(fullfile(out,'summary.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(stats));fclose(fid);
save(fullfile(out,'study.mat'),'X','ids','T','F','Z','A','C','K','dur','obs90','z','pred','chosen','models','betaall','R','stats');
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultFigureVisible','off');
f=figure('Position',[100 100 1000 400]);tiledlayout(1,2);nexttile;scatter3(Z(:,1),Z(:,2),Z(:,3),45,K,'filled');xlabel('Temperature (C)');ylabel('Dry-air flow (kg/h)');zlabel('Humidity ratio (g/kg)');colorbar;title('Estimated rate k (1/min)');nexttile;scatter(A,K,25,Z(:,1),'filled');xlabel('Reference capacity A (g)');ylabel('Estimated k (1/min)');colorbar;grid on;savefigs(f,figdir,'01_conditions_parameters');
f=figure('Position',[100 100 1050 650]);tiledlayout(2,3);sel=round(linspace(1,n,6));
for ii=sel,i=ii;s=curves{i};nexttile;plot(s(:,6),s(:,8),'k.','MarkerSize',3);hold on;plot(s(:,6),A(i)*(-expm1(-K(i)*s(:,6))),'Color',[.5 .5 .5]);plot(s(:,6),A(i)*(-expm1(-pred(i,1)*s(:,6))),'b-');plot(s(:,6),A(i)*(-expm1(-pred(i,2)*s(:,6))),'r--');title(sprintf('Run %d, condition %d',ids(i),C(i)));xlabel('Time (min)');ylabel('Water loss (g)');grid on;end
legend('Observed','Per-run fit','LOCO linear','LOCO MLP','Location','best');savefigs(f,figdir,'02_curve_predictions');
f=figure('Position',[100 100 1000 400]);tiledlayout(1,2);nexttile;scatter(K,pred(:,1),25,'b','filled');hold on;scatter(K,pred(:,2),25,'r');plot([min(K),max(K)],[min(K),max(K)],'k--');xlabel('Per-run estimated k');ylabel('Held-out predicted k');legend('Linear','MLP','Location','best');grid on;nexttile;boxchart(R(:,3),R(:,5));xticks(1:4);xticklabels({'Linear','MLP seed17','MLP seed41','MLP seed73'});ylabel('Curve RMSE (g)');grid on;savefigs(f,figdir,'03_validation');
f=figure('Position',[100 100 1000 400]);tiledlayout(1,2);nexttile;scatter(obs90,log(10)./pred(:,1),25,'b','filled');hold on;scatter(obs90,log(10)./pred(:,2),25,'r');mx=max([obs90;log(10)./pred(:,1);log(10)./pred(:,2)]);plot([0 mx],[0 mx],'k--');xlabel('Observed t90 (min)');ylabel('Predicted t90 (min)');legend('Linear','MLP','Location','best');grid on;nexttile;u=linspace(0,1,m);E=F-(-expm1(-T.*K'));plot(u,mean(E,2),'k','LineWidth',1.5);yline(0,'--');xlabel('Fraction of recorded duration');ylabel('Mean observed minus per-run model (L/A)');grid on;savefigs(f,figdir,'04_time_residual');
f=figure('Position',[100 100 1000 350]);tiledlayout(1,3);b=linearfit(z,T,F,K);p=netfit(z,T,F,b,median(chosen),17);
for j=1:3,nexttile;zz=zeros(101,3);zz(:,j)=linspace(-1,1,101)';plot(zz(:,j),exp([ones(101,1),zz]*b),'b-');hold on;plot(zz(:,j),netpredict(p,zz),'r--');xlabel(['Standardized factor ',num2str(j)]);ylabel('k (1/min)');grid on;end
legend('Linear','MLP','Location','best');savefigs(f,figdir,'05_parameter_response');
disp(stats);
end
function b=linearfit(z,t,f,k)
 Q=[ones(size(z,1),1),z];init=Q\log(k);obj=@(b)mean(mean((-expm1(-t.*exp(Q*b)')-f).^2,1));b=fminsearch(obj,init,optimset('MaxIter',2000,'MaxFunEvals',5000,'TolX',1e-9,'Display','off'));
end
function p=netfit(z,t,f,b,lambda,seed)
 rng(seed);H=4;W=randn(H,3)*.25;B=zeros(H,1);v=randn(H,1)*.05;c=b(1);p=[W(:);B;v;c];mv=zeros(size(p));vv=mv;
 for epoch=1:1200
  W=reshape(p(1:12),4,3);B=p(13:16);v=p(17:20);c=p(21);h=tanh(W*z'+B);s=v'*h+c;k=exp(s);kt=t.*k;fh=-expm1(-kt);e=fh-f;
  ds=2*mean(e.*kt.*exp(-kt),1)/size(z,1);dh=(v*ds).*(1-h.^2);
  grad=[reshape(dh*z,[],1);sum(dh,2);h*ds';sum(ds)];pen=[p(1:12);zeros(4,1);p(17:20);0];grad=grad+lambda*pen;
  mv=.9*mv+.1*grad;vv=.999*vv+.001*grad.^2;p=p-.015*(mv/(1-.9^epoch))./(sqrt(vv/(1-.999^epoch))+1e-8);
 end
end
function k=netpredict(p,z)
 h=tanh(reshape(p(1:12),4,3)*z'+p(13:16));k=exp(p(17:20)'*h+p(21))';
end
function savefigs(f,folder,name)
 exportgraphics(f,fullfile(folder,[name,'.png']),'Resolution',180);savefig(f,fullfile(folder,[name,'.fig']));close(f);
end
