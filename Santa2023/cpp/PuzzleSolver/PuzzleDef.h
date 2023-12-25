#pragma once

#include <map>
#include <string>
#include <vector>

class PuzzleDef
{
	static std::map<std::string, std::map<std::string, std::vector<int>>> m_puzzle_def;

	std::vector<std::string> m_move_names;
	std::map<std::string, std::vector<int>> m_allowed_moves;
	std::string m_name;

	std::vector<std::vector<int>> m_allowed_moves_vector;	
	

	int m_state_size;
	void GenerateInverseMoves();	

	static void LoadDefinitions();

public:

	PuzzleDef() { m_state_size = 0; };
	PuzzleDef(const std::string& name);

	int move_count() const;	
	std::string move_name(int move_index) const;
	std::string name() const;
	std::vector<std::string> to_move_names(std::vector<int> moves) const;

	void apply_moves(const std::vector<std::string>& moves, const std::vector<int>& initial_state, std::vector <int>& final_state) const;

	void apply_move(const std::string& move, const std::vector<int>& initial_state, std::vector<int>& final_state) const;
	void apply_move(int move_index, const std::vector<int>& initial_state, std::vector<int>& final_state) const;
};

