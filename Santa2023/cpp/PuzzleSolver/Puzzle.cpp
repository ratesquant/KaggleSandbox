#include "Puzzle.h"

#include <nlohmann/json.hpp>  ////https://github.com/nlohmann/json
#include <iostream>
#include <sstream>
#include <fstream>
#include <map>


using json = nlohmann::json;


bool Puzzle::IsEqual(const std::vector<int>& state1, const std::vector<int>& state2) const
{
	if (state1.size() != state2.size())
		return false;

	int diff_count = 0;
	for (size_t i = 0; i < state1.size(); i++)
	{
		if (state1[i] != state2[i])
		{
			diff_count++;

			if(diff_count > m_wildcards_num)
				return false;
		}
	}
	return true;
}

int Puzzle::Diff(const std::vector<int>& state1, const std::vector<int>& state2) const
{
	if (state1.size() != state2.size())
		return std::max(state1.size(), state2.size());

	int diff_count = -m_wildcards_num;
	for (size_t i = 0; i < state1.size(); i++)
	{
		if (state1[i] != state2[i])
		{
			diff_count++;
		}
	}
	return std::max(0, diff_count);
}

std::vector<std::string> Puzzle::StateFromString(const std::string& state_string, bool one_char_state)
{
	std::vector<std::string> state;

	if (one_char_state)
	{
		state.resize(state_string.size());

		for (size_t i = 0; i < state.size(); i++)
		{
			state[i] = state_string[i];
		}
	}
	else
	{
		//NOT supported yet
	}

	return state;	
}

std::vector<Puzzle> Puzzle::Load(const std::string& filename)
{
	std::vector<Puzzle> my_puzzles;
	
	std::ifstream puzzle_info_file(filename);
	json puzzle_info = json::parse(puzzle_info_file);

	std::cout << "Loading puzzles from: " << filename << std::endl;

	//[{"index": 0, "puzzle_type" : "cube_2/2/2", "num_wildcards" : 0, "solution_state" : "AAAABBBBCCCCDDDDEEEEFFFF", "initial_state" : "DEDAEBABCACADCDFFFEEBFBC", "moves" : ["r1", "-f1"] }

	for (auto it : puzzle_info)
	{
		int index = it["index"];

		if (index != my_puzzles.size()) 
		{
			std::cout<<"Puzzle index does not match!"<< std::endl;
		}

		std::string puzzle_type = it["puzzle_type"];
		int num_wildcards = it["num_wildcards"];
		std::vector<std::string> solution_state = it["solution_state"];
		std::vector<std::string> initial_state = it["initial_state"];
		std::vector<std::string> moves = it["moves"];

		PuzzleDef my_puzzle_type(puzzle_type);
		Puzzle my_puzzle(my_puzzle_type, initial_state, solution_state, num_wildcards, moves);

		my_puzzles.push_back(my_puzzle);
	}
	std::cout << "Loaded " << my_puzzles.size()<< " puzzles" << std::endl;
	return my_puzzles;
}

Puzzle::Puzzle(const PuzzleDef& puzzle_type, const std::vector<std::string>& initial_state, const std::vector<std::string>& solution_state, int wildcards_num, const std::vector<std::string>& solution)
{
	init_state_map(initial_state);

	m_puzzle_type = puzzle_type;
	m_initial_state = translate_state(initial_state);
	m_solution_state = translate_state(solution_state);
	m_wildcards_num = wildcards_num;
	m_solution = solution;
}

void Puzzle::init_state_map(const std::vector<std::string>& state)
{
	m_state_names.clear();
	m_state_names_inverse.clear();

	for (size_t i = 0; i < state.size(); i++)
	{
		if (m_state_names.find(state[i]) == m_state_names.end())
		{
			int index = m_state_names.size();
			m_state_names.insert(std::pair<std::string, int>(state[i], index));
			m_state_names_inverse.insert(std::pair<int, std::string>(index, state[i]));
		}
	}
}

std::vector<int> Puzzle::translate_state(const std::vector<std::string>& state) const
{
	std::vector<int> res(state.size());

	for (size_t i = 0; i < state.size(); i++)
	{	
		res[i] = m_state_names.at(state[i]);
	}
	return res;
}


const std::vector<int>& Puzzle::initial_state() const
{
	return m_initial_state;
}
const std::vector<int>& Puzzle::solution_state() const
{
	return m_solution_state;
}
const PuzzleDef& Puzzle::puzzle_type() const
{
	return m_puzzle_type;
}
int Puzzle::wildcards_num() const
{
	return m_wildcards_num;
}

const std::vector<std::string>& Puzzle::solution() const
{
	return m_solution;
}
