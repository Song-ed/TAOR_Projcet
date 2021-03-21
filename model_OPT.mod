# This is the model file for optimization problem
# You need to upload the model file with data file and command file to the server
# Using the NEOS server for BARON/AMPL
# The model must be in AMPL format

#  define the sets
set Manufacturers ordered;      #  two manufacturers {inf, dap}
set Sectors ordered;        	#  two sectors {public, private}

#  define the parameters
param gamma >= 0;                 #  product similarity gamma
param demand >= 0;                #  total demand D
param mu >= 0;                         #  objective function weight mu

param a{Sectors};                       #  demand curve coefficients a, b, c
param b{Sectors};
param c{Sectors};

param K{Manufacturers} >=0;  #  production capacity {K_inf, K_dap}
param P{Manufacturers} >=0;  #  target profit {P_inf, P_dap}
param rho{Manufacturers} >=0;  #  public sector price upper bound {rho_inf, rho_dap}

param U = a[last(Sectors)]*(1+gamma)/gamma * (1-2*(1-gamma)^(1/2)/((1+gamma)^(1/2)*(2-gamma)));

#  define the variables
var price{Sectors, Manufacturers} >=0;
var quant{Sectors, Manufacturers} >=0;
var z;                                             #  price difference
var PubCost >=0;                        #  PubCost = price{pub,inf}*quant{pub,inf}+price{pub,dap}*quant{pub,dap}


#  OBJECTIVE FUNCTION
#  minimize the public sector cost and the price difference
minimize goal:
	mu*PubCost + (1-mu)*z;


#  CONSTRAINTS
#  compute the public sector cost
subject to compute_PubCost:
	PubCost = sum{m in Manufacturers} price[first(Sectors), m] * quant[first(Sectors), m];

#  compute the price difference
subject to compute_z{m in Manufacturers, n in Manufacturers: m <> n}:
	z >= price[first(Sectors), m]-price[first(Sectors), n];

#  meet the public sector demand
subject to public_demand:
	sum{m in Manufacturers} quant[first(Sectors), m] >= 0.57*demand;

#  meet the private sector demand
subject to private_demand:
	sum{m in Manufacturers} quant[last(Sectors), m] >= 0.43*demand;

#  meet the demand curve
subject to demand_curve{s in Sectors, m in Manufacturers, n in Manufacturers: m <> n}:
	a[s] = quant[s,m] + b[s]*price[s,m] - c[s]*price[s,n];

#  meet the target profit
subject to target_profit{m in Manufacturers}:
	sum{s in Sectors} quant[s,m] * price[s,m] >= P[m];

#  meet the capacity
subject to capacity{m in Manufacturers}:
	sum{s in Sectors} quant[s,m] <= K[m];

#  meet the remaining prodection capacity threshold U
subject to threshold{m in Manufacturers}:
	K[m] - quant[first(Sectors), m] >= U;
	
#  meet the BC equilibrium private sector price
subject to private_price{m in Manufacturers}:
	price[last(Sectors), m] = a[last(Sectors)]/(2*b[last(Sectors)] - c[last(Sectors)]);

#  meet the inflation price upper bound
subject to inflation_price{m in Manufacturers}:
	price[first(Sectors), m] <= rho[m];
