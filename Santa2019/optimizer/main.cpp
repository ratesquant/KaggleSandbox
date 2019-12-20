#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <omp.h>
#include <unistd.h> 

#include <iostream>
#include <iomanip>
#include <ctime>
#include <numeric>
#include <algorithm>

#include <vector>
#include <string>
#include <random>
#include <chrono>

#include "Request.h"

using namespace std;

class my_random
{
   std::mt19937 m_rgen; 
   double m_r_scale;

   public:
      my_random(unsigned seed = std::chrono::system_clock::now().time_since_epoch().count()): m_rgen(seed)
      {
         m_r_scale = 1.0 / ((double)m_rgen.max() + 1);         
      }  

      inline const double operator()() //random number in thge interval [0, 1)
      {
         return m_r_scale * m_rgen();         
      } 
};

int solver_1(const Request& request, const std::vector<int>& schedule, std::vector<int>& solution)
{
  solution = schedule;
  double cur_objective = request.objective(schedule);

  unsigned seed1 = std::chrono::system_clock::now().time_since_epoch().count();

  std::mt19937 rgen (seed1);
  std::cout << "Random value: " << double(rgen()) / rgen.max() << std::endl;

  int ng = request.group_count();

  for(int i=0; i<10000000; i++)
  {
     int g_index = floor( solution.size() * double(rgen())  / rgen.max() );
     int r_day  = 1 + floor( 100 * (double)rgen()  / rgen.max() ); //from [1 to 100]
     int r_choice  = floor( 10 * (double)rgen()  / rgen.max() ); //from [0 to 9]
     int prev = solution[g_index];

     if( rgen() < 0.1 * rgen.max() )
        solution[g_index] = r_day;
     else
        solution[g_index] = request.get_choice(g_index, r_choice);

     double new_objective = request.objective(solution);

     if(new_objective<cur_objective)
     {
          std::cout << i << ": " << cur_objective<< "->" << new_objective << ", " << cur_objective - new_objective << std::endl;
          cur_objective = new_objective;
     }else
     {
          solution[g_index] = prev;
     }
  }
}

int shuffle(std::vector<int>& schedule)
{
   my_random rgen;

   for(int i=0; i<schedule.size(); i++)
   {
      schedule[i] = 1 + floor( 100.0 * rgen() ); 
   }
}

int partial_shuffle(int n, std::vector<int>& schedule)
{
   my_random rgen;

   for(int i=0; i<n; i++)
   {
      int index = floor( schedule.size() * rgen());

      schedule[index] = 1 + floor( 100.0 * rgen() ); 
   }
}
//assign random date to each family
int solver_2(const Request& request, const std::vector<int>& schedule, std::vector<int>& solution, int n_rounds = 1, double initial_temp = 1.0)
{
   std::cout << "Random Chooser Plus" << std::endl;

   double choice_mult = 1.0;
   double constr_mult = 1.0; //1.0 = 1000 per violation
   double acct_mult = 1.0;

   std::vector<int> cur_solution = schedule; 

   double cur_objective = request.objective(schedule, choice_mult, constr_mult, acct_mult);
   double best_objective = cur_objective;

   solution = schedule; //this is what we return
   
   my_random rgen;   

   int ng = request.group_count();
   
   int n_round_size = (int)1e6;   
   //double temperature = initial_temp; 
   //double final_temp = 0.01; 
   //double temperature_multiplier = exp(log(final_temp/initial_temp)/n_rounds );

   //std::cout << "temp: " << temperature<< ", rounds: " << n_rounds << std::endl;   

   for(int i=0; i<n_rounds; i++)
   {
      //double temperature = std::max(0.0, initial_temp*(1.0-1.1*double(i)/n_runs) );
      //double temperature = std::max(0.0, initial_temp*exp(-double(i)/n_runs) * (0.8 + 0.2*cos(100*double(i)/n_runs)) );
      double temperature = initial_temp * 0.5*(1.0 + cos(50*double(i)/n_rounds));
      //double temperature = initial_temp;

      int solution_updated_count = 0;

      for(int j=0; j<n_round_size; j++)
      {
         int r_day  = 1; //from [1 to 100]

         //try swapping days
         bool is_swap = rgen() < 0.1; //10% change of swap 

         int g_index1, g_index2, prev1, prev2; 

         bool is_change = true;

         g_index1 = floor( solution.size() * rgen());
         
         if(is_swap)
         {         
            g_index2 = floor( solution.size() * rgen());
                  
            prev1 = cur_solution[g_index1];
            prev2 = cur_solution[g_index2];

            cur_solution[g_index1] = prev2;
            cur_solution[g_index2] = prev1;

            r_day = prev2;

            is_change = (g_index1 != g_index2);

         }else{       
            if( rgen() < 0.01  ) //1% chance to pick random date            
               r_day = 1 + floor( 100.0 * rgen() ); //from [1 to 100]
            else
               r_day = request.get_choice(g_index1, floor( 10.0 * rgen() )); //from [0 to 9];
            
            prev1 = cur_solution[g_index1];      
            cur_solution[g_index1] = r_day;

            is_change = (prev1 != r_day);
         }   

         double new_objective = is_change ? request.objective(cur_solution, choice_mult, constr_mult, acct_mult) : cur_objective;
         //double new_objective = request.objective(cur_solution, choice_mult, constr_mult, acct_mult);

         if(new_objective<best_objective)
         {
            std::cout << i << "-"<<j<< " :" << best_objective<< " -> " << new_objective << ", " << best_objective - new_objective<< " temp: " << temperature << " ["<<g_index1<<"]: " <<prev1<< " -> " <<r_day <<" swap: " << is_swap <<  std::endl;
            best_objective = new_objective;
            solution = cur_solution;
            solution_updated_count++;
         }

         if( new_objective < cur_objective || rgen() < exp( -(new_objective - cur_objective)/temperature) )
         {
            cur_objective = new_objective;
         }else
         {
            //roll back
            if(is_swap)
            {
               cur_solution[g_index1] = prev1;
               cur_solution[g_index2] = prev2;
            }else
            {
               cur_solution[g_index1] = prev1;
            }
         }        
      }//end of round

      std::cout << std::setw(4)<< i << ": ";
      std::cout << std::setprecision( 2 ) << cur_objective << ", ";         
      std::cout << std::setprecision( 2 ) << cur_objective - best_objective << ", ";
      std::cout << std::setprecision( 2 ) << "temp: " << temperature << ", ";      
      std::cout << " updates: " << solution_updated_count; 
      std::cout << std::endl;   

      //temperature = solution_updated ? temperature : temperature_multiplier * temperature;            
      
      //reset to best found solution every 10 rounds
      if( i % 10  == 0)
      {
         cur_solution = solution;
      }    
   }
}

//Swapper
int solver_3(const Request& request, const std::vector<int>& schedule, std::vector<int>& solution, int n_rounds = 1, double initial_temp = 1.0)
{
   std::cout << "Random Swapper " << std::endl;

   std::vector<int> cur_solution = schedule; 

   double cur_objective = request.objective(schedule);
   double best_objective = cur_objective;

   solution = schedule; //this is what we return

   unsigned seed1 = std::chrono::system_clock::now().time_since_epoch().count();

   std::mt19937 rgen (seed1);

   double r_scale = 1.0 / ((double)rgen.max() + 1);

   int ng = request.group_count();
   
   int n_round_size = (int)1e6;
   int n_runs = (int)(n_rounds*n_round_size);   

   std::cout << "temp: " << initial_temp<< ", rounds: " << n_rounds << std::endl;

   for(int i=0; i<n_runs; i++)
   {
      //double temperature = std::max(0.0, initial_temp*(1.0-1.1*double(i)/n_runs) );
      //double temperature = std::max(0.0, initial_temp*exp(-double(i)/n_runs) * (0.8 + 0.2*cos(100*double(i)/n_runs)) );
      double temperature = initial_temp * 0.5*(1.0 + cos(100*double(i)/n_runs));

      int g_index1 = floor( solution.size() * r_scale * rgen());
      int g_index2 = floor( solution.size() * r_scale * rgen());
            
      int prev1 = cur_solution[g_index1];
      int prev2 = cur_solution[g_index2];

      if(prev2 == prev1)
         continue; //skip

      cur_solution[g_index1] = prev2;
      cur_solution[g_index2] = prev1;

      double new_objective = request.objective(cur_solution);

      if(new_objective<best_objective)
      {
         std::cout << i << ": " << best_objective<< " -> " << new_objective << ", " << best_objective - new_objective<< " temp:= " << temperature << std::endl;         
         best_objective = new_objective;
         solution = cur_solution;
      }

      if( new_objective < cur_objective || r_scale * rgen() < exp( -(new_objective - cur_objective)/temperature) )
      {            
         cur_objective = new_objective;
      }else
      {
         //roll back
         cur_solution[g_index1] = prev1;
         cur_solution[g_index2] = prev2;
      }

      if(i % n_round_size == 0)
      {
         std::cout << std::setw(4)<< i / n_round_size << ": ";
         std::cout << std::setprecision( 2 ) << cur_objective << ", ";
         std::cout << std::setprecision( 2 ) << cur_objective/best_objective << ", ";
         std::cout << std::setprecision( 2 ) << cur_objective - best_objective << ", ";
         std::cout << std::setprecision( 2 ) << "temp: " << temperature;
         std::cout << std::endl;
      }
   }
}

//Greedy Chooser
int solver_4(const Request& request, const std::vector<int>& schedule, std::vector<int>& solution, int n_rounds = 1)
{
   std::cout << "Greedy Chooser" << std::endl;

   my_random rgen;

   std::vector<int> cur_solution = schedule; 
   std::vector<int> blank_solution(schedule.size(), 0);

   solution = cur_solution; //return initial value

   double solution_obj = request.objective(solution); 

   for(int k=0; k<n_rounds; k++)
   {
      //reset solution 
      cur_solution = blank_solution;            

      int n_assigned = 0;

      while(n_assigned < cur_solution.size())
      {
         int g_index1 = floor( cur_solution.size() * rgen());

         if(cur_solution[g_index1] == 0)
         {
            double best_obj = 1e12;
            int best_day = 1;
            //loop over all days to find the best placement
            for(int j = 0; j < 100; j++)
            {
               cur_solution[g_index1] =  j + 1;           
               double curr_obj = request.objective(cur_solution);            

               if(curr_obj < best_obj)
               {
                  best_obj = curr_obj;       
                  best_day = j + 1;      
               }
            }
            cur_solution[g_index1] = best_day;
            n_assigned++;
         }
      }

      double obj = request.objective(cur_solution); 
      if(obj < solution_obj)
      {
         solution_obj = obj;
         solution = cur_solution;
      }

      std::cout << std::setw(4)<< k << ": ";
      std::cout << std::setprecision( 2 ) << obj << ", ";         
      std::cout << std::setprecision( 2 ) << obj - solution_obj << ", ";      
      std::cout << std::endl;
   }    

}


int main(int argc, char* argv[])
{
   //inputs -n 10 -t 1.0 -f solution.csv
   std::string input_filename = "./data/ex/solution.csv";

   int rounds = 10;  ////1 - in 24 sec, 100 - 40 min,  900 - 6h, 3000 - 10h
   double initial_temp = 10.0;
   int solver = 2;
   
   int c;
   while( ( c = getopt (argc, argv, "n:t:f:s:") ) != -1 ) 
   {
      switch(c)
      {
         case 'n':
               if(optarg) 
               { 
                  rounds = std::atoi(optarg); 
                  std::cout<<"Rounds: " << rounds << std::endl;
               }
               break;
         case 't':
               if(optarg)
               {                  
                  initial_temp = std::atof(optarg); 
                  std::cout<<"Initial Temperature: " << initial_temp << std::endl;
               } 
               break;
         case 'f':
               if(optarg)
               {                  
                  input_filename = std::string(optarg); 
                  std::cout<<"Input Filename: " << input_filename << std::endl;
               } 
               break;
         case 's':
               if(optarg)
               {                  
                  solver = std::atoi(optarg); 
                  std::cout<<"Solver : " << solver << std::endl;
               } 
               break;
      }
   }

   std::clock_t start_clock = std::clock();

   std::string data_filename("/home/chirokov/source/github/KaggleSandbox/Santa2019/data/family_data.csv");
   std::string schedule_filename(input_filename);

   Request request(data_filename);

   std::vector<int> schedule;
   Request::read_schedule(schedule_filename, schedule);

   double starting_objective = request.objective(schedule);

   //  std::cout<<"schedule size: "<<schedule.size()<<std::endl;
   std::cout<<"Starting Objective: "<<std::fixed << std::setprecision( 6 )<<starting_objective<<std::endl;  

   std::vector<int> solution = schedule;
   //solver_1(request, schedule, solution);

   //shuffle(schedule);

   if(solver == 2)
   {      
      solver_2(request, schedule, solution, rounds, initial_temp);
   }else if (solver == 3)
   {
      solver_3(request, schedule, solution, rounds, initial_temp);
   }else if (solver == 4)
   {
       solver_4(request, schedule, solution, rounds);
   }   

   double final_objective = request.objective(solution);

   std::cout<<std::fixed << std::setprecision( 6 )<<final_objective<<" improvement: "<< starting_objective - final_objective<< " elapsed: "<<  (1.0/60.0)*double(clock() - start_clock)/CLOCKS_PER_SEC <<std::endl;

   Request::save_schedule(input_filename, solution);

   return 0;
}
