// Microclimates Analysis
// 30 Jan 2020 - Started by Cat
// Level: Species on INTERCEPTS and SLOPES

data {
  
	int<lower=1> N;
	int<lower=1> n_sp;
	int<lower=1, upper=n_sp> sp[N];
	vector[N] y; 		// response
	vector[N] urban; 	// urban predictor
	vector[N] hobo; 	// hobo predictor
		
	}
	
transformed data {
  vector[N] inter_urbanhobo;                 

  inter_urbanhobo = urban .* hobo; 
}

parameters {
  
  real mu_a_sp;   
  real mu_b_urban_sp;     
  real mu_b_hobo_sp;
  real<lower=0> sigma_a_sp; 
  real<lower=0> sigma_b_urban_sp;
  real<lower=0> sigma_b_hobo_sp;
  real<lower=0> sigma_y; 
  
  real mu_b_um_sp; // slope of urban x hobo effect
  real<lower=0> sigma_b_um_sp;
  
  real a_sp[n_sp]; // intercept for species
  
  vector[n_sp] b_urban_ncp; // slope of urban effect 
  vector[n_sp] b_hobo_ncp; // slope of hobo effect 
  
  vector[n_sp] b_um_ncp;
  
	}

transformed parameters {
  vector[N] yhat;

  vector[n_sp] b_urban = mu_b_urban_sp + sigma_b_urban_sp*b_urban_ncp; 
  vector[n_sp] b_hobo = mu_b_hobo_sp + sigma_b_hobo_sp*b_hobo_ncp; 
  vector[n_sp] b_um = mu_b_um_sp + sigma_b_um_sp*b_um_ncp;
  
  for(i in 1:N){    
    yhat[i] = a_sp[sp[i]] + // indexed with species
		          b_urban[sp[i]] * urban[i] + 
		          b_hobo[sp[i]] * hobo[i] +
		          b_um[sp[i]] *  inter_urbanhobo[i];
	      }
	      
}

model {
	a_sp ~ normal(mu_a_sp, sigma_a_sp); 
	b_urban_ncp ~ normal(0, 1);
	b_hobo_ncp ~ normal(0, 1);
	b_um_ncp ~ normal(0, 1);
	
	mu_b_um_sp ~ normal(0, 10);
	sigma_b_um_sp ~ normal(0, 10);
	      
        mu_a_sp ~ normal(400, 50);
        sigma_a_sp ~ normal(0, 50);

        mu_b_urban_sp ~ normal(0, 75);
        sigma_b_urban_sp ~ normal(0, 20);
        
        mu_b_hobo_sp ~ normal(0, 150);
        sigma_b_hobo_sp ~ normal(0, 20);
        
        sigma_y ~ normal(0, 50);
	      
	y ~ normal(yhat, sigma_y);

}

generated quantities{
   real y_ppc[N];
   for (n in 1:N)
      y_ppc[n] = a_sp[sp[n]] + 
		b_urban[sp[n]] * urban[n] +
		b_hobo[sp[n]] * hobo[n];
    for (n in 1:N)
      y_ppc[n] = normal_rng(y_ppc[n], sigma_y);

}