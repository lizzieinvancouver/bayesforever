//
// This Stan program defines a linear model predicting LTE50 from temperature, with partial pooling of variety and year 
//
// Stan model for partially pooled linear regression including priors 
//
//centered parameters for effect of variety on alpha and beta 

data {

	//Level 1
	int < lower = 1 > N; 						// Sample size - number of observations
	vector[N] x; 								// Predictor
	vector[N] y; 								// Outcome

	//Level 2 	
	int < lower = 1 > n_vars; 					// number of random effect levels (varieties) 
	int < lower = 1, upper = n_vars > variety[N]; // id of random effect (variety)

	int < lower = 1 > K; 						// number of random effect levels (years) 
	int < lower = 1, upper = K > year[N]; 		// id of random effect (year)

	}

parameters {

	//level 1
	real < upper = 0 > alpha_g; 				// mean intercept accross all varieties. Grand mean
	real beta_g;								//grand slope accross all varieties
	real <lower =0> sigma_y; 					// overall variation accross observations

	//level 2				  

	vector<lower = 0>[2] var_sigma; 			// a vector of standard deviations, one for alpha and one for beta (overall effect of variety)
	corr_matrix[2] Rho; 	
	vector[n_vars] za_variety;					// z score of alpha for effect of variety 
	vector[n_vars] zb_variety;					// z score of beta for effect of variety 


	real <lower = 0> sigma_k; 					// variation of intercept amoung varieties  
	real yearmu[K];

}
transformed parameters {

 	vector[2] v_variety[n_vars];				//vector of an z scores of alpha and beta value for each varity 
  	for(j in 1:n_vars) { 
  		v_variety[j] = [za_variety[j], zb_variety[j]]'; //put the two effects in a single list 
  	}

}

model{
  
	//---extra parametres 

	//alpha and beta for each variety
  	vector[n_vars] var_alpha;					// a new alpha for each variety, which includes grand alpha and effect of variety 
	vector[n_vars] var_beta;					// a new beta for each variety, which includes grand alpha and effect of variety 

	real ymu[N];								 //Individual mean predicted y value for each x value 
	
	//---Priors 

	//Level 1
	alpha_g ~ normal(-15,12); 					// prior for grand alpha, assumes intercept will negative and around -10.
	//i chose this because -3 is minimum hardiness (least hardy) and few vines can manage temps much lower than -27
	beta_g ~ lognormal(0,1);
	sigma_y ~ normal(0,3); 						// prior around estiamted mean LTE50.

	//Level 2 - year
	yearmu ~ normal(0,sigma_k); 				// prior for the effect of random factor on grand mean 
	sigma_k ~ normal(0, 3); 					// prior for the variety around levels of random factor. Same as sigma_y

	//Level 2 - variety
	var_sigma ~ normal(0, 3); 					// prior for the variety effect that gets multiplied with rho (correlation)
	Rho ~ lkj_corr_lpdf(2); 					// prior for teh correlation between alpha and beta effect of variety 

	target += multi_normal_lpdf(v_variety | rep_vector(0, 2), Rho);

	//---Linear model
	for(j in 1:n_vars){

		var_alpha[j] = alpha_g + za_variety[j] * var_sigma[1]; // get an alpha for each variety 
		var_beta[j] = beta_g + zb_variety[j] * var_sigma[2]; // get a beta for each variety  

	}

	for (i in 1:N){
		ymu[i] = var_alpha[variety[i]] + yearmu[year[i]] + var_beta[variety[i]] * x[i];

	}

	//---liklihood
	for (i in 1:N){	
		y[i] ~ normal(ymu[i], sigma_y);
	}
}
generated quantities {
  vector[N] var_alpha;
  vector[N] var_beta;
  vector[N] ymu;
  
  var_alpha = alpha_g + za_variety[variety] * var_sigma[1]; // get an alpha for each variety 
	var_beta = beta_g + zb_variety[variety] * var_sigma[2]; // get a beta for each variety  

  for (i in 1:N){
		ymu[i] = var_alpha[variety[i]] + yearmu[year[i]] + var_beta[variety[i]] * x[i];
	}
	
} // The posterior predictive distribution
