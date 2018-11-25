#include "StdAfx.h"
#include "MCSolver.h"

#include "Nodes.h"

template <typename T>
std::vector<size_t> sort_indexes(const std::vector<T> &v) {

  // initialize original index locations
  std::vector<size_t> idx(v.size());
  iota(idx.begin(), idx.end(), 0);

  // sort indexes based on comparing values in v
  std::sort(idx.begin(), idx.end(),
       [&v](size_t i1, size_t i2) {return v[i1] < v[i2];});

  return idx;
}

void mutate_tour(const std::vector<int>& tour, int start_index, int n_tour_size, std::vector<int>& next_tour)
{
	//first and last point of each tour is 0 and does not change
	double scale = (double) (n_tour_size - 2) /(RAND_MAX + 1.0);

	//pick 2 induces between [start_index + 1, start_index + 1 + n_tour_size] and reverse path between them  
	int index_1 = start_index + 1 + (int)floor(scale * rand());
	int index_2 = start_index + 1 + (int)floor(scale * rand());

	int s_index = std::min(index_1, index_2);
	int e_index = std::max(index_1, index_2);

    //copy unchanged
	for(int i=start_index; i<s_index; i++)
		next_tour[i] = tour[i];

	//reverse direction
	for(int i=s_index; i<=e_index; i++)
		next_tour[i] = tour[e_index + s_index - i];

	//copy unchanged
	for(int i=e_index+1; i<start_index + n_tour_size; i++)
		next_tour[i] = tour[i];
}

double mean(const std::vector<double>& x)
{
	double avg = 0.0;

	for(int i=0; i<x.size(); i++)
	{
		avg += x[i];
	}

	return avg/x.size();
}

double amin(const std::vector<double>& x)
{
	double min_x = x[0];

	for(int i=0; i<x.size(); i++)
	{
		if( x[i] < min_x) min_x = x[i];
	}

	return min_x;
}

const std::vector<int> MCSolver::run_iterations(const std::vector<int>& tour, int maxit, int p_size) const
{
	int n_best = std::max(1, int(0.95 * p_size));
	int n_tour_size = tour.size();

	std::vector<double> scores(p_size);
	std::vector<double> next_scores(p_size);

	std::vector<int> tours(p_size * n_tour_size);
	std::vector<int> next_tours(p_size * n_tour_size);

	std::vector<int> best_tour = tour;
	double best_score;


	//initialize all tours to the same value
	for(int i=0; i<p_size * n_tour_size; i++)
	{
		tours[i] = tour[i % n_tour_size];		
	}

	//compute all scores
	for(int i=0; i<p_size; i++)
	{
		scores[i] = m_nodes.tour_distance(tours, i * n_tour_size,  n_tour_size);
	}
	std::vector<size_t> score_index = sort_indexes(scores);

	best_score = scores[0];

	clock_t clock_start = clock();	
	

	for(int it=0; it<maxit; it++)
	{			
		//mutate all, replace "n_best" worst with unchanged "n_best" tours from previous iteration	

		//mutate all tours
		for(int i=0; i<p_size; i++)
		{
			mutate_tour(tours, i * n_tour_size, n_tour_size, next_tours);

			//compute new scores
			next_scores[i] = m_nodes.tour_distance(next_tours, i * n_tour_size,  n_tour_size);
		}

		std::vector<size_t> next_score_index = sort_indexes(next_scores);

		//update best score
		int best_tour_index = next_score_index[0];
			
		if(next_scores[best_tour_index] <  best_score)
		{
			best_score = next_scores[best_tour_index];
			
			for(int i=0; i<n_tour_size; i++)
			{
				best_tour[i] = next_tours[i+best_tour_index * n_tour_size];
			}
		}

        //replace "n_best" of worst with best from previous tours
		for(int i=0; i<n_best; i++)
		{	
			int p_index1 = score_index[i];
			int p_index2 = next_score_index[p_size - 1 - i];

			if(next_scores[p_index2] > scores[p_index1] )
			{
				int index1 = p_index1 * n_tour_size;
				int index2 = p_index2 * n_tour_size;

				for(int j=0; j<n_tour_size; j++)
				{
					next_tours[j + index2] = tours[j + index1];
				}
				next_scores[p_index2] =  scores[p_index1];
			}

		}
		
		if(it % 10 == 0)
		{
			clock_t clock_end = clock();

			std::cout<<"it, "<<it<<", ";
			std::cout<<"best score, "<<best_score<<", ";
			std::cout<<"mean score, "<<mean(next_scores)<<", ";
			std::cout<<"time, "<<clock_end -  clock_start<<", ";
			std::cout<<std::endl;

			clock_start = clock_end;
		}

		//next iteration
		tours = next_tours;
		scores = next_scores;
	}

	return best_tour;
}


MCSolver::~MCSolver(void)
{
}

