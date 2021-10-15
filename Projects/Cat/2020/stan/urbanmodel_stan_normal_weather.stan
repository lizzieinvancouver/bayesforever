// Microclimates Analysis
// 30 Jan 2020 - Started by Cat
// Level: Species on INTERCEPTS and SLOPES

data {
	int<lower=1> N;
	int<lower=1> n_sp;
	int<lower=1, upper=n_sp> sp[N];
	vector[N] y; 		// response
	vector[N] tx; 	// urban predictor
		
	}

parameters {
  real mu_a_sp;   
  real mu_b_tx_sp;     
  real<lower=0> sigma_a_sp; 
  real<lower=0> sigma_b_tx_sp; 
  real<lower=0> sigma_y; 

  real a_sp[n_sp]; // intercept for species
  real b_tx[n_sp]; // slope of urban effect 

	}

transformed parameters {
  vector[N] yhat;
  
       	for(i in 1:N){
            yhat[i] = a_sp[sp[i]] + // indexed with species
		b_tx[sp[i]] * tx[i];
	}
}

model {

	a_sp ~ normal(mu_a_sp, sigma_a_sp); 
	b_tx ~ normal(mu_b_tx_sp, sigma_b_tx_sp);  

        mu_a_sp ~ normal(250, 100);
        sigma_a_sp ~ normal(0, 100);

        mu_b_tx_sp ~ normal(0, 75);
        sigma_b_tx_sp ~ normal(0, 50);

	y ~ normal(yhat, sigma_y);

}

generated quantities{
   real y_ppc[N];
   for (n in 1:N)
      y_ppc[n] = a_sp[sp[n]] + 
		b_tx[sp[n]] * tx[n];
    for (n in 1:N)
      y_ppc[n] = normal_rng(y_ppc[n], sigma_y);

}