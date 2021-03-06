clear all
clc
close all
%% Stochastic Variable selection algorithm matlab script
% This code is based on conjugate priors 
% If p is no of predictor variables 2^p models are evaluated in each run
% Each MCMC produces a model
% Error term in the model is assumed to be normal and variance unknown
% The variance term is calculated within the MCMC algorithm



%% Generate pseudo random data

init_data.predictor_np=10; % No of predictor terms 
init_data.order=1; % No of order of terms to be included
init_data.N=50;  % Total no of data points 
init_data.predictor=randn([init_data.N,init_data.predictor_np]);  % Random predictor variable generation
init_data=generate_data(init_data);  % Generate data using the order of the data

init_data.noofterms=floor(size(init_data.predictor_column,2)/2); % Randomly select predictor variables
% rng(1,'v5uniform');
% init_data.actualmodelterms=randi([1,size(init_data.predictor_column,2)],[init_data.noofterms,1]);
init_data.actualmodelterms=sort(randsample(size(init_data.predictor_column,2),[init_data.noofterms]));
init_data.actualmodelpredictors=init_data.predictor_column(:,init_data.actualmodelterms); 
beta_predictors=4*randn([length(init_data.actualmodelterms),1]); %Beta_coefficient generation
init_data.response=init_data.actualmodelpredictors*beta_predictors+0.3*randn([init_data.N,1]); % Actual y term


%% SVSS algorithm initialization

data_available.response=init_data.response;
% data_available.response=zscore(init_data.response);
% data_available.predictor_library=init_data.predictor_column;
data_available.predictor_library=zscore(init_data.predictor_column);
data_available.org_predictor=init_data.predictor; 
data_available.init_pi0=0.5; %Prior belief
data_available.Xvar=2.25^2;

%% MCMC starting

disp('Gibbs sampling running');
disp('%%%%%%%%%%%%%%%');

T=40000;flg=0; % No of MCMC iterations
p=size(init_data.predictor_column,2);
model.heatmap=cell(T,1);
model.global_indicator=cell(T,1);
model.global_indicator{1,1}=ones(1,p);
model.selected=cell((p),1);
model.sumterms=zeros(p,1);
N=length(data_available.response);
data_available.var_Y=11;
list_var=1:1:p;
for t=2:T
    
    model.indicator=model.global_indicator{t-1,1};
    data_available.beta=model.indicator;
    if (rem(t*100/T,20)==0)
        flg=flg+1;
        fprintf('Gibbs sampling: %d percent done\n',20*flg);
    end
    
    for j=1:p
        M1=j;
        M2=find(list_var~=j);
        [bf_inv,pr]=compute_bayes_fac_V2(M1,M2,data_available);
        
        if binornd(1,pr.H0)==1
            model.indicator(1,j)=0; 
            model.betaind(1,j)=0;
        else
            model.indicator(1,j)=normrnd(pr.E,sqrt(pr.V));
            model.betaind(1,j)=1;
        end
        data_available.beta=model.indicator;
    end
    model.residuals=data_available.response-data_available.predictor_library*model.indicator';
    model.B=(sum(model.residuals.^2))*0.5;
    model.phi(t,1)=gamrnd(N/2,1/model.B);
    data_available.var_Y=1/model.phi(t,1);
    model.global_indicator{t,1}=model.indicator;
    model.global_betaindicator{t,1}=model.betaind;
    model.heatmap{t,1}=find(model.indicator~=0);
    if flg>1
    if isempty(model.heatmap{t,1})==0
%         length(model.selected(length(model.heatmap{t,1})))=len;
        model.selected{length(model.heatmap{t,1}),1}(1,end+1)=t; 
        model.sumterms(length(model.heatmap{t,1}),1)=model.sumterms(length(model.heatmap{t,1}),1)+1;
    end
    end
end
%%
[~,Ind] = max(model.sumterms);newjj=1;jj=1;member=[];clstr=0;
while(jj<length(model.selected{Ind,1}))
    tterm=model.selected{Ind,1}(1,jj);cntr=0;
    totmember=0;clstr=clstr+1;newjj=[];
    for kk=jj:length(model.selected{Ind,1})
        tterm2=model.selected{Ind,1}(1,kk);
        comp_model=model.global_betaindicator{tterm2,1};
        if(ismember(comp_model,model.global_betaindicator{tterm,1},'rows'))
            totmember=totmember+1;
            member{clstr,1}(totmember)=tterm2;
            clstrlen(clstr,1)=totmember;
        else
%             clstr=clstr+1
            newjj(1,end+1)=kk;
        end
    end
    if isempty(newjj)
        break
    else
        jj=newjj(1);
    end
end
[~,indc]=max(clstrlen);
model.betarray=cell2mat(model.global_indicator(member{indc,1}));
model.meanbetarray=mean(model.betarray);
disp(model.meanbetarray);