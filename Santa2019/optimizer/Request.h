#pragma once

#include <vector>
#include <string>

class Request
{
    std::vector<int> m_choices;
	std::vector<int> m_people;
public:

	Request(const std::string& filename);

	int group_count() const;
	int get_choice(int group, int choice) const;

	double objective(const std::vector<int>& schedule, const double choice_mult = 1.0, const double constr_mult = 1.0, const double acct_mult = 1.0) const;

	static int read_schedule(const std::string& filename, std::vector<int>& schedule);
	static int save_schedule(const std::string& filename, const std::vector<int>& schedule);

	virtual ~Request();
};
