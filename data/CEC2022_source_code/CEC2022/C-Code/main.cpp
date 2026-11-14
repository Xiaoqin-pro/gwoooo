/*
  L-SHADE implemented by C++ for Special Session & Competition on Real-Parameter Single Objective Optimization at CEC-2014
  See the details of L-SHADE in the following paper:

  * Ryoji Tanabe and Alex Fukunaga: Improving the Search Performance of SHADE Using Linear Population Size Reduction,  Proc. IEEE Congress on Evolutionary Computation (CEC-2014), Beijing, July, 2014.

  Version: 1.0   Date: 16/Apr/2014
  Written by Ryoji Tanabe (rt.ryoji.tanabe [at] gmail.com)
  Modified by Abhishek Kumar (abhishek.kumar.eee13[at]iitbhu.ac.in)
*/

#include "de.h"

double *OShift,*M,*y,*z,*x_bound, *Rn;
int ini_flag=0,n_flag,func_flag,*SS;
FILE *fpt;

int rand_idx;
int g_function_number;
int g_problem_size;
unsigned int g_max_num_evaluations;

int g_pop_size;
double g_arc_rate;
int g_memory_size;
double g_p_best_rate;

int main(int argc, char **argv) {
  //number of runs
  int num_runs = 30;
    //dimension size. please select from 10, 20
  g_problem_size = 10;
  //available number of fitness evaluations: 200000 for D =10, 1000000 for D = 20
  g_max_num_evaluations = 200000;
  //random seed is selected according to competition rules
  fpt = fopen("input_data/Rand_Seeds.txt","r");
  Rn =(double*)malloc(1000*1*sizeof(double));
  for(int i=0;i<1000;i++)
   {
    fscanf(fpt,"%lf",&Rn[i]);
    //cout << Rn[i] << "\n"<<endl;
   }
  fclose(fpt);
  //srand((unsigned)time(NULL));

  //L-SHADE parameters
  g_pop_size = (int)round(g_problem_size * 18);
  g_memory_size = 6;
  g_arc_rate = 2.6;
  g_p_best_rate = 0.11;

 for (int i = 0; i < 12; i++) {
    g_function_number = i + 1;
    cout << "\n-------------------------------------------------------" << endl;
    cout << "Function = " << g_function_number << ", Dimension size = " << g_problem_size << "\n" << endl;

    Fitness *bsf_fitness_array = (Fitness*)malloc(sizeof(Fitness) * num_runs);
    Fitness mean_bsf_fitness = 0;
    Fitness std_bsf_fitness = 0;

    for (int j = 0; j < num_runs; j++) {
      rand_idx = (g_problem_size/10 * g_function_number*num_runs+j+1) - num_runs;
      rand_idx = (rand_idx % 1000);
      //cout << Rn[rand_idx] << "\n" << endl;
      srand(Rn[rand_idx]);
      searchAlgorithm *alg = new LSHADE();
      bsf_fitness_array[j] = alg->run();
      cout << j + 1 << "th run, " << "error value = " << bsf_fitness_array[j] << endl;
    }

    for (int j = 0; j < num_runs; j++) mean_bsf_fitness += bsf_fitness_array[j];
    mean_bsf_fitness /= num_runs;

    for (int j = 0; j < num_runs; j++) std_bsf_fitness += pow((mean_bsf_fitness - bsf_fitness_array[j]), 2.0);
    std_bsf_fitness /= num_runs;
    std_bsf_fitness = sqrt(std_bsf_fitness);

    cout  << "\nmean = " << mean_bsf_fitness << ", std = " << std_bsf_fitness << endl;
    free(bsf_fitness_array);
  }

  return 0;
}
