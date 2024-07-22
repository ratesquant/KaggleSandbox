// PuzzleSolver.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <random>
#include <set>
#include <sstream>
#include <time.h>  
#include <fstream>
#include <omp.h>
#include <nlohmann/json.hpp>  ////https://github.com/nlohmann/json
#include "PuzzleDef.h"
#include "Puzzle.h"

using json = nlohmann::json;
using namespace std;

vector<std::string> random_search(const Puzzle& puzzle, unsigned int max_moves, unsigned int max_it)
{
    std::random_device dev;
    std::mt19937 rng(dev());    

    const PuzzleDef& puzzle_def = puzzle.puzzle_type();

    std::uniform_int_distribution<std::mt19937::result_type> random_move(0, puzzle_def.move_count() -1); // distribution in range [0, move_count-1]

    std::vector<int> solution_state = puzzle.solution_state();
    std::vector<int> initial_state = puzzle.initial_state();
    std::vector<int> state, next_state;

    std::vector<int> best_moves;
    std::vector<int> moves(max_moves);    
    /*
    std::cout << "Random Search: ";
    for (unsigned int i = 0; i < max_moves; i++)
    {
        std::cout << random_move(rng) << ", ";
    }
    std::cout << std::endl;
    */

    for (unsigned int i = 0; i < max_it; i++)     
    {
        state = initial_state;
        next_state = initial_state;
        for (unsigned int j = 0; j < max_moves; j++)
        {
            int move_index = random_move(rng);

            moves[j] = move_index;

            puzzle_def.apply_move(move_index, state, next_state);

            if (puzzle.IsEqual(next_state, solution_state) && (j + 1 < best_moves.size() || best_moves.size() == 0))
            {
                best_moves.resize(j+1);

                for (unsigned int k = 0; k <= j; k++) 
                {
                    best_moves[k] = moves[k];
                }
                break;
            }
            state = next_state;
        }
    }

    std::vector<std::string> move_names(best_moves.size());
    for (unsigned int k = 0; k < best_moves.size(); k++)
    {
        move_names[k] = puzzle_def.move_name(best_moves[k]);
    }        

    return move_names;
}

std::string join_string(std::vector<std::string> items, string delim = ".")
{
    std::ostringstream joined;

    for (size_t i = 0; i + 1 < items.size(); i++) 
    {
        joined << items[i] << delim;
    }

    if (items.size() >= 1) 
    {
        joined << items[items.size() - 1];
    }

    //std::copy(items.begin(), items.end(), std::ostream_iterator<std::string>(joined, delim.c_str()));

    return joined.str();
}


void BenchmarkSolver()
{
    clock_t clock_start = clock();

    PuzzleDef puzzle_type("cube_2/2/2");
    vector<string> initial_solution;
    Puzzle puzzle(puzzle_type, Puzzle::StateFromString("DECBBEFAFDBFFEBDAACDCEAC"), Puzzle::StateFromString("AAAABBBBCCCCDDDDEEEEFFFF"), 0, initial_solution); //hard
    //Puzzle puzzle(puzzle_type, "DEDAEBABCACADCDFFFEEBFBC", "AAAABBBBCCCCDDDDEEEEFFFF", 0); //easy

    //38.852 sec
    std::vector<std::string> solution = random_search(puzzle, 10, (int)1e8);//100m
    std::string solution_string = join_string(solution);

    std::cout << "Solution: " << solution_string << std::endl;

    cout << "Elapsed: " << (double)(clock() - clock_start) / CLOCKS_PER_SEC << endl;
}

void CheckCurrentSolutions(const std::vector<Puzzle>& puzzles)
{
    for (size_t i = 0; i < puzzles.size(); i++)
    {
        clock_t clock_start = clock();

        const PuzzleDef& puzzle_def = puzzles[i].puzzle_type();
        vector<string> solution = puzzles[i].solution();

        std::vector<int> solution_state = puzzles[i].solution_state();
        std::vector<int> initial_state = puzzles[i].initial_state();
        std::vector<int> final_state;

        puzzle_def.apply_moves(solution, initial_state, final_state);

        cout << i << ", ";
        cout << puzzle_def.name() << ", ";
        cout << solution.size() << ", ";    
        cout << (puzzles[i].IsEqual(final_state, solution_state) ? "Valid" : "WRONG") <<"  (" << (double)(clock() - clock_start) / CLOCKS_PER_SEC<< ") " << endl;
    }
}

vector<int> TreeSolver(const Puzzle& puzzle, std::vector<int> initial_state, unsigned int max_depth, vector<int>& moves)
{
    const PuzzleDef& puzzle_def = puzzle.puzzle_type();
    std::vector<int> solution_state = puzzle.solution_state();    

    vector<int> best_moves;

    if (max_depth > 0)
    {
        for (int i = 0; i < puzzle_def.move_count(); i++)
        {
            std::vector<int> state = initial_state;

            puzzle_def.apply_move(i, initial_state, state);

            moves.push_back(i);

            if (puzzle.IsEqual(state, solution_state))
            {
                return moves;
            }
            else
            {
                vector<int> res = TreeSolver(puzzle, state, max_depth - 1, moves);

                if (res.size() > 0 && (best_moves.size() == 0 || best_moves.size() > res.size()) )
                {
                    best_moves = res;
                }

                moves.pop_back();
            }
        }
    }
    return best_moves;
}

void RunSolverBatch(const std::vector<Puzzle>& puzzles, unsigned int max_it, unsigned int max_moves)
{
    //set<string> exclude_types = { "cube_19/19/19", "cube_33/33/33" };
    set<string> exclude_types = { "wreath_21/21", "wreath_33/33", "wreath_100/100", "globe_1/8", "globe_1/16", "globe_2/6", "globe_3/4", "globe_6/4", "globe_6/10", "globe_3/33", "globe_8/25"};

    vector<vector<std::string>> best_moves(puzzles.size());

    cout << "RunSolverBatch: " << max_it << endl;
    
    int imp_count = 0;
    int solved = 0;

    vector<int> move_count(puzzles.size());
    for (int i = 0; i < puzzles.size(); i++)
    {
        move_count[i] = puzzles[i].solution().size();
    }


    #pragma omp parallel for num_threads(4)
    for (int i = 0; i < puzzles.size(); i++)
    {
        const PuzzleDef& puzzle_def = puzzles[i].puzzle_type();

        best_moves[i] = puzzles[i].solution();

        if (exclude_types.find(puzzle_def.name()) != exclude_types.end()) 
        {   
            std::vector<int> solution_state = puzzles[i].solution_state();
            std::vector<int> initial_state = puzzles[i].initial_state();
            std::vector<int> final_state;
           
            unsigned int n_moves = std::max(1, move_count[i]);
            unsigned int n_it = 1 + max_it / (1 + n_moves/100);

            if (n_moves < 10) 
            {
                n_it = std::min(n_it, (unsigned int)1e6);
            }

            vector<std::string> result = random_search(puzzles[i], std::min(n_moves - 1, max_moves), n_it);

            #pragma omp critical
            {
                solved++;

                cout << "Solved puzzle:" << i << " (" << puzzle_def.name() << ") " << " moves: " << n_moves << ", found: "<< result.size() << ", solved:"<< solved << ", it: "<< log10(n_it);

                if (result.size() < move_count[i] && result.size() > 0)
                {
                    imp_count += result.size() - best_moves[i].size();

                    best_moves[i] = result;

                    cout << ", better solution found:" << "(" << result.size() << ") " << " moves: " << join_string(result);                    
                }
                cout << endl;
            }            
        }
    }

    cout << "Total improvement: " << imp_count << endl;

    //save results
    string filename = "D:/Github/KaggleSandbox/Santa2023/data/solution_submission_cpp.csv";    
    std::ofstream ofs(filename.c_str(), std::ofstream::out);

    ofs << "id,moves" << endl;
    for (size_t i = 0; i < puzzles.size(); i++)
    {
        ofs <<i<<","<< join_string(best_moves[i])  << std::endl;
    }
    ofs.close();
}

void RunSolverBatchTree(const std::vector<Puzzle>& puzzles, unsigned int max_it)
{    
    vector<vector<std::string>> best_moves(puzzles.size());

    int imp_count = 0;
    int solved = 0;

    vector<int> move_count(puzzles.size());
    for (int i = 0; i < puzzles.size(); i++)
    {
        move_count[i] = puzzles[i].solution().size();
    }


#pragma omp parallel for num_threads(2)
    for (int i = 0; i < puzzles.size(); i++)
    {
        const PuzzleDef& puzzle_def = puzzles[i].puzzle_type();

        best_moves[i] = puzzles[i].solution();

        std::vector<int> solution_state = puzzles[i].solution_state();
        std::vector<int> initial_state = puzzles[i].initial_state();
        std::vector<int> final_state;

        int n_moves = move_count[i];
        int m_allowed_moves = puzzle_def.move_count();        
        int max_depth = std::max(1, std::min(n_moves - 1, 1 + int(log(max_it) / log(m_allowed_moves))));
        
        vector<int> moves;
        vector<int> result_index = TreeSolver(puzzles[i], puzzles[i].initial_state(), max_depth, moves);
        vector<string> result = puzzles[i].puzzle_type().to_move_names(result_index);

#pragma omp critical
        {
            solved++;

            cout << "Solved puzzle:" << i << " (" << puzzle_def.name() << ") " << " moves: " << move_count[i]<<", allowed moves:"<< m_allowed_moves<<", max depth:"<< max_depth << ", found: " << result.size() << ", solved:" << solved;

            if (result.size() < move_count[i] && result.size() > 0)
            {
                imp_count += result.size() - best_moves[i].size();

                best_moves[i] = result;

                cout << ", better solution found:" << "(" << result.size() << ") " << " moves: " << join_string(result);
            }
            cout << endl;
        }        
    }

    cout << "Total improvement: " << imp_count << endl;

    //save results
    string filename = "D:/Github/KaggleSandbox/Santa2023/data/solution_submission_cpp.tree.csv";
    std::ofstream ofs(filename.c_str(), std::ofstream::out);

    ofs << "id,moves" << endl;
    for (size_t i = 0; i < puzzles.size(); i++)
    {
        ofs << i << "," << join_string(best_moves[i]) << std::endl;
    }
    ofs.close();
}

void RunSolver(const Puzzle puzzle, unsigned int max_it, unsigned int max_try)
{    
    int imp_count = 0;
    int solved = 0;

    const PuzzleDef& puzzle_def = puzzle.puzzle_type();

    vector<string> best_moves = puzzle.solution();

    std::vector<int> solution_state = puzzle.solution_state();
    std::vector<int> initial_state = puzzle.initial_state();
    std::vector<int> final_state;

    //save results
    string filename = "D:/Github/KaggleSandbox/Santa2023/data/cpp.log";
    std::ofstream ofs(filename.c_str(), std::ofstream::out);

    for(unsigned int i = 0; i< max_try; i++)
    {          
        int n_moves = best_moves.size();            

        vector<std::string> result = random_search(puzzle, n_moves - 1, max_it);
            
        cout << "It:" << i << " (" << puzzle_def.name() << ") " << " moves: " << n_moves << ", found: " << result.size();
        ofs  << "It:" << i << " (" << puzzle_def.name() << ") " << " moves: " << n_moves << ", found: " << result.size();

        if (result.size() < n_moves && result.size() > 0)
        {
            imp_count += result.size() - best_moves.size();

            best_moves = result;

            cout << ", better solution found:" << "(" << result.size() << ") " << " moves: " << join_string(result);
            ofs << ", better solution found:" << "(" << result.size() << ") " << " moves: " << join_string(result);
        }
        cout << endl;
        ofs << endl;
    }    
    
    ofs.close();
}

int main()
{
    clock_t clock_start = clock();

    std::cout << "Puzzle Solver" << std::endl;    

    std::vector<Puzzle> puzzles = Puzzle::Load("D:/Github/KaggleSandbox/Santa2023/data/puzzles.json");

    //23, cube_2/2/2, moves: 9, allowed: 12, ['d0', 'f0', 'r0', '-r1', '-d0', '-r0', '-f1', '-r1', 'r0'] (0.0 sec)
    if (false)
    {
        clock_start = clock();

        int puzzle_index = 23;
        vector<int> moves;
        vector<int> best_moves = TreeSolver(puzzles[puzzle_index], puzzles[puzzle_index].initial_state(), 9, moves); //1.34 min for depth = 8
        vector<string> best_moves_str = puzzles[puzzle_index].puzzle_type().to_move_names(best_moves);

        //max_depth = min(len(moves) - 1, int(log(1e8) / log(len(allowed_moves))))

        cout << puzzle_index << ", " << join_string(best_moves_str) << endl;
    }
    //RunSolverBatchTree(puzzles, (int)1e9);

    //CheckCurrentSolutions(puzzles);

    //RunSolver(puzzles[391], (int)1e6, 100);
    RunSolverBatch(puzzles, (int)1e7, 10000);

    //BenchmarkSolver();

    //void RunSolver();
    
    std::cout << "Elapsed: " << (((double)clock() - (double)clock_start) / CLOCKS_PER_SEC)/60.0  <<" min" << std::endl;


    //std::string state = puzzle.initial_state();
    //puzzle_type.apply_move("f0", puzzle.initial_state(), state);
}
