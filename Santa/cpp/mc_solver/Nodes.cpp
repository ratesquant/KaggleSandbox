#include "StdAfx.h"
#include "Nodes.h"

using namespace std;

Nodes::Nodes(const string& filename)
{
	std::ifstream ifs (filename.c_str(), std::ifstream::in);
	
	node_x.resize(0);
	node_y.resize(0);
	node_p.resize(0);

	//CityId,X,Y,not_prime

    //read header
	string s;
	getline( ifs, s );

	while (ifs)
	{
		
		if (!getline( ifs, s )) break;
		
		istringstream ss( s );
		vector <string> record;
		while (ss)
		{
			string s;
			if (!getline( ss, s, ',' )) break;
			record.push_back( s );
		}

		int city_id = atof(record[0].c_str());

		if(city_id!=node_x.size())
			throw std::exception("wrong city id");

		if(record.size()!=4)
			throw std::exception("wrong record size");

		node_x.push_back(atof(record[1].c_str()));
		node_y.push_back(atof(record[2].c_str()));
		node_p.push_back(atoi(record[3].c_str()));
	}

	ifs.close();
}

double Nodes::tour_distance(const std::vector<int>& tour) const
{
	int prev_id = tour[0];

	double total_dist = 0.0;

	for(int i=1; i<tour.size(); i++)
	{
		int curr_id = tour[i];

		double dx = node_x[curr_id] - node_x[prev_id];
		double dy = node_y[curr_id] - node_y[prev_id];

		double dist = sqrt(dx * dx + dy * dy);

		if( i % 10==0 & node_p[prev_id])
		{
			dist = 1.1 * dist;
		}
		prev_id = curr_id;

		total_dist += dist;
	}
	return total_dist;
}

double Nodes::tour_distance(const std::vector<int>& tour, int start_index, int n_tour_size) const
{
	int prev_id = tour[start_index];

	double total_dist = 0.0;

	for(int j=1; j<n_tour_size; j++)
	{
		int i = start_index + j;

		int curr_id = tour[i];

		double dx = node_x[curr_id] - node_x[prev_id];
		double dy = node_y[curr_id] - node_y[prev_id];

		double dist = sqrt(dx * dx + dy * dy);

		if( j % 10==0 & node_p[prev_id])
		{
			dist = 1.1 * dist;
		}
		prev_id = curr_id;

		total_dist += dist;
	}
	return total_dist;
}

Nodes::~Nodes(void)
{
}
