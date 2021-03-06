clear all
close all

%% Constants
tic
n=["GaAs"];
shape=["Uniform"];
L = [0, 300, 0];

% MgF2      94
% ZnS       44
% AlGaAs	25
% GaAs      300
% InGaP     100
% AlGaAs	100
% Ag        100

lab1=300;
lab2=999;
lam0_r=lab1:lab2;
len_lab=length(lam0_r);

eps_lab=get_lab(lab1,lab2);

Rtot=zeros(size(lam0_r));
Ttot=zeros(size(lam0_r));

h = waitbar(0,'Please wait...');

for iter=1:len_lab
    theta	= 0;                % Angle with respect to normal 0<theta<pi/2
    phi     = 0;                % Angle with respect to -x 0<theta<2pi
    pte     = 1;                % TE component
    ptm     = 0;                % TM component
    lam0    =lam0_r(iter);
    k_0     =2*pi/lam0;
    
    labda_x=100; % unit cell size (nm)
    labda_y=100; % unit cell size (nm)
    lenx=512; % unit cell grid x
    leny=512; % unit cell grid y
    P=3;
    Q=3;
    num_H=P*Q;
    
    %harmonics=10*labda_x/lam
    
    M=-(P-1)/2:(P-1)/2;
    N=-(Q-1)/2:(Q-1)/2;
    
    [eps_r,mu_r]=build_perm(n,shape,lenx,leny,P,Q,eps_lab,iter);
    
    %% Simulation
    
    % Starting parameters
    [Kx,Ky,Kz] = calc_K(lam0,theta,phi,eps_r,mu_r,M,N,labda_x,labda_y);
    S_global = {zeros(2*num_H),eye(2*num_H);eye(2*num_H),zeros(2*num_H)};
    
    % Free space
    P_0 = calc_PQ(eye(size(Kx)),eye(size(Kx)),Kx,Ky);
    Q_0 = calc_PQ(eye(size(Kx)),eye(size(Kx)),Kx,Ky);
    [W_0, eigval0]=eig(P_0*Q_0);
    V_0=Q_0*W_0*inv(sqrt(eigval0));
    
    % Loop through layers
    for i=1:length(L)
        [S,W{i},V{i},l{i}] = calc_layer(V_0,W_0,mu_r{i},eps_r{i},Kx,Ky,k_0*L(i));
        Sg{i} = S_global;
        S_global = RH_star(S_global,S);
    end
    

    
    % Polarizations
    n_inc=1; % needs generalization
    k_inc = [sin(theta)*cos(phi),sin(theta)*sin(phi),cos(theta)]';%*k_0*n_inc;
    normal=[0;0;-1];
    
    TE_direction=cross(k_inc,normal)/norm(cross(k_inc,normal));
    nancheck=all(isnan(TE_direction));
    TE_direction(isnan(TE_direction))=0;
    a_TE=TE_direction+nancheck*[0,1,0]';
    a_TM=cross(a_TE,k_inc)/norm(cross(a_TE,k_inc));
    
    p=pte*a_TE+ptm*a_TM;
    
    p=p/norm(p);
    
    delta=zeros(num_H,1);
    delta(ceil(end/2))=1; %only central harmonic
    
    E_inc{1} = delta*p(1);
    E_inc{2} = delta*p(2);
    
    c_inc=inv(W{1})*[E_inc{1};E_inc{2}];
    
    c_ref=S_global{1,1}*c_inc;
    c_trn=S_global{2,1}*c_inc;
    
    % Calculate fields by backward propagation
%     for i=length(L):-1:2
%         c_mn{i}=inv(Sg{i-1}{1,2})(c_ref-Sg{i-1}{1,1}*c_inc)
%         c_pl{i}=Sg{i-1}{2,1}*C_inc+Sg{i-1}{2,2}*c_mn
%     end
    
    
    [E_ref{1},E_ref{2}]=split_xy(W{1}*c_ref);
    [E_trn{1},E_trn{2}]=split_xy(W{end}*c_trn);
    
    E_ref{3}=-inv(Kz{1})*(Kx*E_ref{1}+Ky*E_ref{2});
    E_trn{3}=-inv(Kz{end})*(Kx*E_trn{1}+Ky*E_trn{2});
    E_inc{3}=-inv(Kz{1})*(Kx*E_inc{1}+Ky*E_inc{2});
    
    Rmag=abs(E_ref{1}).^2+abs(E_ref{2}).^2+abs(E_ref{3}).^2;
    R=real(Kz{1}/k_inc(3))*Rmag;
    Rtot(iter)=sum(R(:));
    
    Tmag=abs(E_trn{1}).^2+abs(E_trn{2}).^2+abs(E_trn{3}).^2;
    T=real((mu_r{1}/mu_r{end})*(Kz{end}/k_inc(3)))*Tmag;
    Ttot(iter)=sum(T(:));
    
    if Ttot>1
        error("T over 1")
    end
    waitbar(iter/len_lab,h)
end
toc

delete(h)

Abs(:,1)=1-Rtot-Ttot;
Abs(:,2)=Rtot;
Abs(:,3)=Ttot;
pll=[lab1:lab2';lab1:lab2';lab1:lab2']';
area(pll,Abs)
legend("GaAs","R","T")
ylim([-0.1,1.1])
xlim([lab1-0.1*(lab2-lab1),lab2+0.1*(lab2-lab1)])