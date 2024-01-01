#pragma once
#include <string>
#include "PuzzleDef.h"

class Puzzle
{
	PuzzleDef m_puzzle_type;
	int m_wildcards_num;
	std::vector<int> m_initial_state;
	std::vector<int> m_solution_state;
	std::vector<std::string> m_solution;

	std::map<std::string, int> m_state_names;
	std::map<int, std::string> m_state_names_inverse;

	void init_state_map(const std::vector<std::string>& state);
	std::vector<int> translate_state(const std::vector<std::string>& state) const;


	public:

		Puzzle(const PuzzleDef& puzzle_type,  const std::vector<std::string>& initial_state, const std::vector<std::string>& solution_state, int wildcards_num, const std::vector<std::string>& solution);		
				
		const std::vector<int>& initial_state() const;
		const std::vector<int>& solution_state() const;
		const PuzzleDef& puzzle_type() const;
		const std::vector<std::string>& solution() const;

		bool IsEqual(const std::vector<int>& state1, const std::vector<int>& state2) const;
		int Diff(    const std::vector<int>& state1, const std::vector<int>& state2) const;

		static std::vector<std::string> StateFromString(const std::string& state_string, bool one_char_state = true);

		int wildcards_num() const;

		static std::vector<Puzzle> Load(const std::string& filename);
};

