// mc_solver.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include "Nodes.h"
#include "MCSolver.h"

using namespace std;

int read_tour(const string& filename, vector<int>& tour)
{
	std::ifstream ifs (filename.c_str(), std::ifstream::in);
	
	tour.resize(0);	

	while (ifs)
	{
		string s;
		
		if (!getline( ifs, s )) break;

		tour.push_back(atoi(s.c_str()));
	}

	if(tour.back()!= 0)
		tour.push_back(0);

	ifs.close();

	return 0;
}

int save_tour(const string& filename, const vector<int>& tour)
{
	std::ofstream ofs (filename.c_str(), std::ofstream::out);
	
	for(size_t i=0; i<tour.size(); i++)
	{
		ofs<<tour[i]<<std::endl;
	}
	ofs.close();

	return 0;
}


int _tmain(int argc, _TCHAR* argv[])
{
    //string filename("F:/Github/KaggleSandbox/Santa/data/cities_ex.csv");
	//string tour_filename("F:/Github/KaggleSandbox/Santa/data/concorde_tour.lin.txt");
	//string solution_filename("F:/Github/KaggleSandbox/Santa/data/cpp.solution.tour.all.txt");

	string filename("F:/Github/KaggleSandbox/Santa/data/cities_ex.csv");
    //string tour_filename("F:/Github/KaggleSandbox/Santa/data/tour.all.txt");
	string tour_filename("F:/Github/KaggleSandbox/Santa/data/cpp.solution.tour.txt");
	string solution_filename("F:/Github/KaggleSandbox/Santa/data/cpp.solution.tour.txt");

	//string filename("F:/Github/KaggleSandbox/Santa/data/cities_ex.1k.csv");
	//string tour_filename("F:/Github/KaggleSandbox/Santa/data/tour.1k.txt");
	//string solution_filename("F:/Github/KaggleSandbox/Santa/data/cpp.solution.tour.1k.txt");	

	//string filename("F:/Github/KaggleSandbox/Santa/data/cities_ex.csv");
	//string tour_filename("F:/Github/KaggleSandbox/Santa/data/concorde_tour.lin.txt");
	//string solution_filename("F:/Github/KaggleSandbox/Santa/data/cpp.solution.tour.all.txt");

	//string filename("C:/Dev/Kaggle/Santa/data/cities_ex.100.csv");
	//string tour_filename("C:/Dev/Kaggle/Santa/data/tour.100.csv");
	//string solution_filename("C:/Dev/Kaggle/Santa/data/cpp.solution.tour.100.txt");

   //string filename("C:/Dev/Kaggle/Santa/data/cities_ex.csv");
   //string tour_filename("C:/Dev/Kaggle/Santa/data/concorde_tour.lin.txt");
   //string solution_filename("C:/Dev/Kaggle/Santa/data/cpp.solution.tour.all.txt");

	//tour_filename = solution_filename; // do one more iteration

	Nodes nodes(filename);

    // read sample tour
	vector<int> tour;
	read_tour(tour_filename, tour);
	
	clock_t start = clock();	

	double starting_distance = nodes.tour_distance(tour);

	cout<<"Starting tour distance: "<<std::fixed << std::setprecision( 6 ) <<starting_distance<<",("<<clock()-start<<")"<<std::endl;

	// run simulation

	MCSolver solver(nodes);

	//int maxit  =  100;//000;
	int maxit  =  2;
	int p_size =  100;
	int span = 1000; 
    //span 100   - 0.5 sec per it
	//span 1000  - 4.0 sec per it
	//span  5000  - 20 sec
	//span 10000  - 40 sec

    //int method = 1; //reverse everything between 2 nodes (usually the best)
	//int method = 2; //swap two nodes
	int method = 3; //move a position of a single node
	//int method = 4; //reverse everything between 2 nodes (full span), 460 sec per it

  //std::vector<int> best_tour = solver.run_iterations(tour, maxit, p_size);

	//cout<<"Final tour distance: "<<std::fixed << std::setprecision( 6 ) << nodes.tour_distance(tour)<<", ";
	//cout<<"Final tour distance: "<<std::fixed << std::setprecision( 6 ) << nodes.tour_distance(tour, 0, tour.size())<<", ";
	
	
	std::vector<int> best_tour = solver.random_search(tour, method, maxit, span);

	double final_distance = nodes.tour_distance(best_tour);

	cout<<"Final tour distance: "<<std::fixed << std::setprecision( 6 ) << final_distance<<", ";
	cout<<"Improvement: "<<std::fixed << std::setprecision( 6 ) <<  starting_distance - final_distance <<std::endl;
	 
	if(final_distance<starting_distance)
	{
		save_tour(solution_filename, best_tour);

		cout<<"Saved to: "<<solution_filename <<std::endl;
	}

	//save tour

    //197769

	return 0;
}


