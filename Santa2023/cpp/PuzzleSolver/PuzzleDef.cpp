#include <nlohmann/json.hpp>  ////https://github.com/nlohmann/json
#include <iostream>
#include <sstream>
#include <fstream>

#include "PuzzleDef.h"

using json = nlohmann::json;

std::map<std::string, std::map<std::string, std::vector<int>>> PuzzleDef::m_puzzle_def;

void PuzzleDef::LoadDefinitions()
{
	std::string puzzle_def_file = "D:/Github/KaggleSandbox/Santa2023/data/puzzle_info.json";
	std::ifstream puzzle_info_file(puzzle_def_file);
	json puzzle_info = json::parse(puzzle_info_file);

	std::cout << "Loading puzzle definition from: " << puzzle_def_file << std::endl;

	for (json::iterator it = puzzle_info.begin(); it != puzzle_info.end(); ++it) 
	{
		std::string puzzle_name = it.key();

		std::cout << puzzle_name << ": ";

		std::map < std::string, std::vector<int>> move_def;

		for (json::iterator jt = it.value().begin(); jt != it.value().end(); ++jt)
		{
			std::vector<int> moves;

			for (int i = 0; i < jt.value().size(); i++)
			{
				moves.push_back(jt.value()[i]);
			}

			move_def[jt.key()] = moves;			
		}		

		PuzzleDef::m_puzzle_def[puzzle_name] = move_def;

		std::cout << move_def.size() << " moves" <<std::endl;
	}
}

PuzzleDef::PuzzleDef(const std::string& name)
{	
	m_name = name;

	if (m_puzzle_def.size() == 0) 
	{
		PuzzleDef::LoadDefinitions();
	}

	if (m_puzzle_def.find(name) != m_puzzle_def.end())
	{
		m_allowed_moves = m_puzzle_def[name];
	}
	else 
	{
		std::cout << "No definition is found for the "<< name << std::endl;
	}
	/*
	if (name == "cube_2/2/2") 
	{
		m_allowed_moves["f0"] = { 0, 1, 19, 17, 6, 4, 7, 5, 2, 9, 3, 11, 12, 13, 14, 15, 16, 20, 18, 21, 10, 8, 22, 23 };
		m_allowed_moves["f1"] = { 18, 16, 2, 3, 4, 5, 6, 7, 8, 0, 10, 1, 13, 15, 12, 14, 22, 17, 23, 19, 20, 21, 11, 9 };
		m_allowed_moves["r0"] = { 0, 5, 2, 7, 4, 21, 6, 23, 10, 8, 11, 9, 3, 13, 1, 15, 16, 17, 18, 19, 20, 14, 22, 12 };
		m_allowed_moves["r1"] = { 4, 1, 6, 3, 20, 5, 22, 7, 8, 9, 10, 11, 12, 2, 14, 0, 17, 19, 16, 18, 15, 21, 13, 23 };
		m_allowed_moves["d0"] = { 0, 1, 2, 3, 4, 5, 18, 19, 8, 9, 6, 7, 12, 13, 10, 11, 16, 17, 14, 15, 22, 20, 23, 21 };
		m_allowed_moves["d1"] = { 1, 3, 0, 2, 16, 17, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, 18, 19, 20, 21, 22, 23 };	
	}*/

	m_state_size = m_allowed_moves.begin()->second.size();

	GenerateInverseMoves();

	m_allowed_moves_vector.resize(m_move_names.size());
	for (size_t i = 0; i < m_move_names.size(); i++)
	{
		m_allowed_moves_vector[i] = m_allowed_moves.at(m_move_names[i]);
	}
}

int  PuzzleDef::move_count() const
{
	return m_allowed_moves.size();
}

void PuzzleDef::GenerateInverseMoves()
{
	std::vector<std::string> keys;
	keys.reserve(m_allowed_moves.size());
	for (std::map<std::string, std::vector<int>>::iterator it = m_allowed_moves.begin(); it != m_allowed_moves.end(); ++it)
	{
		keys.push_back(it->first);
	}

	for (size_t i = 0; i < keys.size(); i++)
	{
		const std::vector<int>& permutation = m_allowed_moves.at(keys[i]);
		std::vector<int> inv_permutation(m_state_size);
		
		for (size_t k = 0; k < permutation.size(); k++)
		{
			inv_permutation[permutation[k]] = k;
		}
		m_allowed_moves["-" + keys[i]] = inv_permutation;
	}
	
	m_move_names.reserve(m_allowed_moves.size());
	for (std::map<std::string, std::vector<int>>::iterator it = m_allowed_moves.begin(); it != m_allowed_moves.end(); ++it)
	{
		m_move_names.push_back(it->first);
	}
}

std::string  PuzzleDef::move_name(int move_index) const
{
	return m_move_names[move_index];
}

std::string  PuzzleDef::name() const
{
	return m_name;
}

void PuzzleDef::apply_move(int move_index, const std::vector<int>& initial_state, std::vector<int>& final_state) const
{
	const std::vector<int>& permutation = m_allowed_moves_vector[move_index];

	for (size_t i = 0; i < permutation.size(); i++)
	{
		final_state[i] = initial_state[permutation[i]];
	}
}

void PuzzleDef::apply_moves(const std::vector<std::string>& moves, const std::vector<int>& initial_state, std::vector<int>& final_state) const
{
	std::vector<int> state = initial_state;
	std::vector<int> next_state = state;
	for (size_t i = 0; i < moves.size(); i++) 
	{
		PuzzleDef::apply_move(moves[i], state, next_state);

		state = next_state;
	}
	final_state = state;
}

void PuzzleDef::apply_move(const std::string& move, const std::vector<int>& initial_state, std::vector<int>& final_state) const
{
	const std::vector<int>& permutation = m_allowed_moves.at(move);
		
	for (size_t i = 0; i < permutation.size(); i++) 
	{
		final_state[i] = initial_state[permutation[i]];
	}
}