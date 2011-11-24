function t = qtt_tucker(varargin)
%QTT_TUCKER(ARRAY,SZ,EPS)

if (nargin == 0)
    t.core=tt_tensor; %The Tucker core
    t.tuck=cell(0); %The tucker factors (in the QTT format)
    t.dphys=0; %Number of physical dimensions
    t.sz=0; %Additional dimensions for each factor
    t = class(t, 'qtt_tucker');
    return;
end

% Copy CONSTRUCTOR
if (nargin == 1) && isa(varargin{1}, 'qtt_tucker')
    t.core = varargin{1}.core;
    t.tuck = varargin{1}.tuck;
    t.sz = varargin{1}.sz;
    t.dphys=varargin{1}.dphys;
    return;
end
%From tt_matrix (unfold)
%if ( nargin == 1 ) && isa(varargin{1},'tt_matrix');
%  tm=varargin{1};
%  t=tm.tt;
%  return;
%end
%From tt_array (stack)
%if ( nargin == 1 ) && isa(varargin{1},'tt_array');
%  ta=varargin{1};
%  t=ta.tt;
%  return;
%end

%From full format
if (  nargin ==3 && isa(varargin{1},'double') && isa(varargin{2},'cell') && isa(varargin{3},'double'))
    %The method is as follows. %Tr
    a=varargin{1};
    sz1=numel(a);
    sz=varargin{2};
    eps=varargin{3};
    eps0=eps;
  
    %Get physical dimensions from quantized ones
    d=numel(sz);
    n=zeros(d,1);
    for i=1:d
      n(i)=prod(sz{i});
    end
      if ( sz1 ~= prod(n) )
       error('qtt_tucker: check_sizes');
    end
    rtt=zeros(d+1,1); %TT-ranks
    rtuck=zeros(d,1);
    tuck=cell(d,1); 
    rtt(1)=1; rtt(d)=1;
    tt_core=[];
    for i=1:d
       a=reshape(a,[rtt(k-1),n(k),rtt(k)]);
       %First, compute the 
       a=permute(a,[2,1,3]);
       a=reshape(a,[n(k),numel(a)/n(k)]);
       [u,s,v]=svd(a,'econ');
       s=diag(s);
       r=my_chop2(s,norm(s)*eps0);
       rtuck{i}=r;
       u=u(:,1:r); s=s(1:r);
       v=v(:,1:r); 
       u=u*diag(s); %This is a good  Tucker factor
       u=reshape(u,[sz{i},r]); 
       tuck{i}=tt_tensor(u,eps0);
       [tuck{i},rm]=qr(tuck{i},'lr');
       v=rm*v'; %a was n(k),rtt(k-1)*M
       %v is rxrtt
       v=reshape(v,[r,rtt(k-1),numel(v)/(r*rtt(k-1))]);
       v=permute(v,[2,3,1]); 
       v=reshape(v,[rtt(k-1)*r,numel(v)/(r*rtt(k-1))]);
       [u1,s1,v1]=svd(v,'econ');
       s1=diag(s1); 
       r1=my_chop2(s1,norm(s1)*eps);
       rtt(i)=r1;
       u1=u1(:,1:r1);s1=s1(1:r1); v1=v1(:,1:r1);
       a=diag(s1)*v1;
       tt_core=[tt_core,u1(:)];
    end
    cr=tt_tensor;
    cr.d=d;
    cr.n=rtuck;
    cr.r=rtt;
    cr.core=tt_core;
    cr.ps=cumsum([1;cr.n.*cr.r(1:cr.d).*cr.r(2:cr.d+1)]);
    t.core=cr;
    t.tuck=tuck;
    t.dphys=d;
    t.sz=sz;
    
end


return
