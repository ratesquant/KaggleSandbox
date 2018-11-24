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
	
	for(int i=0; i<tour.size(); i++)
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

	string filename("F:/Github/KaggleSandbox/Santa/data/cities_ex.100.csv");
	string tour_filename("F:/Github/KaggleSandbox/Santa/data/tour.100.txt");
	string solution_filename("F:/Github/KaggleSandbox/Santa/data/solution.tour.100.txt");

	Nodes nodes(filename);

    // read sample tour
	vector<int> tour;
	read_tour(tour_filename, tour);
	
	clock_t start = clock();	
	
	cout<<"Starting tour distance: "<<std::fixed << std::setprecision( 6 ) <<nodes.tour_distance(tour)<<"("<<clock()-start<<")"<<std::endl;

	// run simulation

	MCSolver solver(nodes);

	int maxit = 10;
	int p_size = 100;

	std::vector<int> best_tour = solver.run_iterations(tour, maxit, p_size);

	cout<<"Starting tour distance: "<<std::fixed << std::setprecision( 6 ) << nodes.tour_distance(best_tour)<<std::endl;
	 
	save_tour(solution_filename, best_tour);

	// save tour

    //197769

	return 0;
}


