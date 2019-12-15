#include "Request.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <math.h>
#include <assert.h>

using namespace std;

const int N_CHOICES = 10;
const int MAX_OCCUPANCY = 300;
const int MIN_OCCUPANCY = 125;
const int N_DAYS = 100;

Request::Request(const string& filename)
{
	std::ifstream ifs (filename.c_str(), std::ifstream::in);

	m_choices.resize(0);
	m_people.resize(0);

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

		if(record.size()!=N_CHOICES+2)
            throw std::runtime_error("wrong record size");

		int family_id = atoi(record[0].c_str());

		if(family_id != m_people.size())
			throw std::runtime_error("wrong family id");

        for(int i=0; i<N_CHOICES; i++)
            m_choices.push_back(atof(record[1+i].c_str()));

        m_people.push_back(atof(record[1+N_CHOICES].c_str()));
	}

	ifs.close();

//	std::cout<<m_choices.size()<<endl;
//	std::cout<<m_people.size()<<endl;
}

int Request::group_count() const
{
   return m_people.size();
}

int Request::get_choice(int group, int choice) const
{
   assert(choice>=0 && choice<N_CHOICES);
   return m_choices[group * N_CHOICES + choice];
}

double Request::objective(const std::vector<int>& schedule, const double choice_mult, const double constr_mult, const double acct_mult) const
{
	double penalty = 0.0;
	static std::vector<int> daily_occupancy(N_DAYS+1, 0); //add one day to handle boundary condition, static - not thread safe, but faster

	std::fill(daily_occupancy.begin(), daily_occupancy.end(), 0);

//	#pragma omp parallel for reduction(+:total_dist)
	for(size_t i=0; i<schedule.size(); i++)
	{
	 	int n = m_people[i];
	 	int day = schedule[i];

	 	daily_occupancy[day-1] += n;

		int index = N_CHOICES*i;

        if(      day == m_choices[index] || day == N_DAYS+1){ }
        else if( day == m_choices[index + 1]){ penalty +=  50; }
        else if( day == m_choices[index + 2]){ penalty +=  50 + 9 * n; }
        else if( day == m_choices[index + 3]){ penalty += 100 + 9 * n; }
        else if( day == m_choices[index + 4]){ penalty += 200 + 9 * n; }
        else if( day == m_choices[index + 5]){ penalty += 200 + 18 * n; }
        else if( day == m_choices[index + 6]){ penalty += 300 + 18 * n; }
        else if( day == m_choices[index + 7]){ penalty += 300 + 36 * n; }
        else if( day == m_choices[index + 8]){ penalty += 400 + 36 * n; }
        else if( day == m_choices[index + 9]){ penalty += 500 + (36 + 199) * n;}
        else{ penalty += 500 + (36 + 398) * n; }
    }
	double extra_day  = daily_occupancy[N_DAYS]; //this day is not subject to constraints 

	daily_occupancy[N_DAYS] = daily_occupancy[N_DAYS-1]; //boundary condition

    double constraint = 0.0;
    //for each date, check total occupancy
    for(size_t i=0; i<daily_occupancy.size(); i++)
    {
        if ( daily_occupancy[i] > MAX_OCCUPANCY )
		{
            constraint += 1000000 * (daily_occupancy[i] - MAX_OCCUPANCY);
			daily_occupancy[i] = MAX_OCCUPANCY;
		}else if (daily_occupancy[i] < MIN_OCCUPANCY)
		{
            constraint += 1000000 * (MIN_OCCUPANCY - daily_occupancy[i]);
			daily_occupancy[i] = MIN_OCCUPANCY;
		}
    }

    // Calculate the accounting cost    
    double accounting_cost = 0.0;
    
    // Loop over the rest of the days, keeping track of previous count
    for(int i = daily_occupancy.size()-2; i >= 0; i--)
    {
        int d_count = daily_occupancy[i];
        int diff = abs(d_count - daily_occupancy[i+1]);
        accounting_cost += ((d_count-125.0) / 400.0) * pow(d_count, (0.5 + diff / 50.0));        
    }

 //   std::cout<<" accounting_cost "<<accounting_cost<<endl;
 //   std::cout<<" penalty "<<penalty<<endl;
 //   std::cout<<" total "<<penalty + accounting_cost<<endl;
  //   std::cout<<" extra_day "<<extra_day<<endl;

	return penalty * choice_mult + constraint * constr_mult +  accounting_cost * acct_mult + extra_day*30.0;
}


int Request::read_schedule(const std::string& filename, std::vector<int>& schedule)
{
	std::ifstream ifs (filename.c_str(), std::ifstream::in);

	schedule.resize(0);

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

		if(record.size() == 2 & atoi(record[0].c_str()) == schedule.size())
            schedule.push_back(atoi(record[1].c_str()));
	}

	ifs.close();

	return 0;
}

int Request::save_schedule(const std::string& filename, const std::vector<int>& schedule)
{
	std::ofstream ofs (filename.c_str(), std::ofstream::out);

	ofs<<"family_id,assigned_day"<<std::endl;

	for(size_t i=0; i<schedule.size(); i++)
	{
		ofs<<i<<','<<schedule[i]<<std::endl;
	}
	ofs.close();

	return 0;
}


Request::~Request(void)
{
}
