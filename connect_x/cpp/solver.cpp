/*
 * This file is part of Connect4 Game Solver <http://connect4.gamesolver.org>
 * Copyright (C) 2007 Pascal Pons <contact@gamesolver.org>
 *
 * Connect4 Game Solver is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Connect4 Game Solver is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with Connect4 Game Solver. If not, see <http://www.gnu.org/licenses/>.
 */

#include <fstream>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <cassert>
#include <ctime>
#include <chrono>
#include <vector>

#include "position.hpp"

using namespace GameSolver::Connect4;

namespace GameSolver { namespace Connect4 {

  /*
   * A class to solve Connect 4 position using Nagemax variant of min-max algorithm.
   */
  class Solver {
    private:
        double m_max_time;
        int m_depth;
        unsigned long long nodeCount; // counter of explored nodes.
        int m_column; 

    int columnOrder[Position::WIDTH]; // column exploration order
    
    /**
     * Reccursively score connect 4 position using negamax variant of alpha-beta algorithm.
     * @param: alpha < beta, a score window within which we are evaluating the position.
     *
     * @return the exact score, an upper or lower bound score depending of the case:
     * - if actual score of position <= alpha then actual score <= return value <= alpha
     * - if actual score of position >= beta then beta <= return value <= actual score
     * - if alpha <= actual score <= beta then return value = actual score
     */
    double negamax(const Position &P, double alpha, double beta, int depth, int &best_column, bool is_root) {
      assert(alpha < beta);
      nodeCount++; // increment counter of explored nodes

      if(P.nbMoves() == Position::WIDTH*Position::HEIGHT) // check for draw game
        return 0; 

      for(int x = 0; x < Position::WIDTH; x++) // check if current player can win next move
        if(P.canPlay(x) && P.isWinningMove(x)) 
          return (Position::WIDTH*Position::HEIGHT+1 - P.nbMoves())/2;

      int max = (Position::WIDTH*Position::HEIGHT-1 - P.nbMoves())/2;	// upper bound of our score as we cannot win immediately
      if(beta > max) {
        beta = max;                     // there is no need to keep beta above our max possible score.
        if(alpha >= beta) return beta;  // prune the exploration if the [alpha;beta] window is empty.
      }

      double best_score = -1000;
      int temp;

      for(int x = 0; x < Position::WIDTH; x++) // compute the score of all possible next move and keep the best one
        if(P.canPlay(columnOrder[x])) {
          Position P2(P);
          P2.play(columnOrder[x]);               // It's opponent turn in P2 position after current player plays x column.

          double score = 0;

          if (depth <= 0)
              score = P.eval(columnOrder[x]); //add position evaluation
          else
          {
              score = -negamax(P2, -beta, -alpha, depth - 1, temp, false); // explore opponent's score within [-beta;-alpha] windows:
                                              // no need to have good precision for score better than beta (opponent's score worse than -beta)
                                              // no need to check for score worse than alpha (opponent's score worse better than -alpha)
          }
          if (score > best_score)
          {
              best_score = score;
              best_column = columnOrder[x];
          }
          //if (is_root)
          //{
          //    std::cout << "col: " << columnOrder[x] << " score:" << score << std::endl;
          //}

          if(score >= beta) return score;  // prune the exploration if we find a possible move better than what we were looking for.
          if(score > alpha) alpha = score; // reduce the [alpha;beta] window for next exploration, as we only 
                                           // need to search for a position that is better than the best so far.
        }

      return alpha;
    }

    public:

    double solve(const Position &P, bool weak = false) 
    {
        nodeCount = 0;
        if(weak) 
            return negamax(P, -1, 1, 16, m_column, true);
        else
        {
            std::clock_t start_clock = std::clock();            

            m_depth = 42;
            double score;
            while (true)
            {
                score =  negamax(P, -Position::WIDTH * Position::HEIGHT / 2, Position::WIDTH * Position::HEIGHT / 2, m_depth, m_column, true);

                double elapsed = double(clock() - start_clock) / CLOCKS_PER_SEC;

                if (fabs(score) >= 1 || score == 0)
                    break;

                if (elapsed * 2.6 > m_max_time)
                    break;

                if (m_depth > Position::WIDTH * Position::HEIGHT - P.nbMoves())
                    break;

                m_depth += 1;
            }
            return score;
            
        }
    }

    unsigned long long getNodeCount() 
    {
      return nodeCount;
    }


    int getColumn()
    {
        return m_column;
    }


    int get_depth()
    {
        return m_depth;
    }

    void set_time(double max_time)
    {
        m_max_time = max_time;
    }


    // Constructor
    Solver() : nodeCount(0), m_max_time(60), m_column(-1) {
      for(int i = 0; i < Position::WIDTH; i++)
        columnOrder[i] = Position::WIDTH/2 + (1-2*(i%2))*(i+1)/2; // initialize the column exploration order, starting with center columns
    }

  };


}} // namespace GameSolver::Connect4


/*
 * Get micro-second precision timestamp
 * uses unix gettimeofday function
 */

/*
 * Main function.
 * Reads Connect 4 positions, line by line, from standard input 
 * and writes one line per position to standard output containing:
 *  - score of the position
 *  - number of nodes explored
 *  - time spent in microsecond to solve the position.
 *
 *  Any invalid position (invalid sequence of move, or already won game) 
 *  will generate an error message to standard error and an empty line to standard output.
 */

int main(int argc, char** argv) {

  Solver solver;

  bool weak = false;

  std::string filename;

  if (argc > 1) filename = argv[1];
  if (argc > 2) solver.set_time( std::atoi(argv[2]) );

  if (!filename.empty()) 
  {
      std::ifstream ifs(filename.c_str(), std::ifstream::in);
      std::ofstream ofs((filename+".out.csv").c_str(), std::ifstream::out);
      
      ofs <<"moves, score, computed_score, column, nodes, depth, elapsed"<< std::endl;

      while (ifs)
      {
          std::string line;

          if (!getline(ifs, line)) break;

          std::istringstream ss(line);
          std::vector <std::string> tokens;
          while (ss)
          {
              std::string s;
              if (!getline(ss, s, ' ')) break;
              tokens.push_back(s);
          }


          Position P;
          if (P.play(tokens[0]) != tokens[0].size())
          {
              std::cerr << ": Invalid move " << (P.nbMoves() + 1) << " \"" << tokens[0] << "\"" << std::endl;
          }
          else
          {
              std::clock_t start_clock = std::clock();

              double score = solver.solve(P, weak);

              double elapsed = double(clock() - start_clock) / CLOCKS_PER_SEC;

              std::cout << tokens[0] << " score: " << score << " column: " << solver.getColumn() << " nodes: " << solver.getNodeCount()<<", depth: "<< solver.get_depth() << ", elapsed: " << elapsed << " sec, rate: " << solver.getNodeCount() / elapsed << std::endl;

              ofs<< tokens[0]<<", "<< tokens[1]<<", "<< score<<", "<< solver.getColumn()<<", " << solver.getNodeCount() << ", " << solver.get_depth()<<", " <<std::fixed << std::setprecision(6)<<elapsed<< std::endl;
              ofs.flush();
          }
      }
      ofs.close();
  }
  else 
  {
      std::string line;

      for (int l = 1; std::getline(std::cin, line); l++) {
          Position P;
          if (P.play(line) != line.size())
          {
              std::cerr << "Line " << l << ": Invalid move " << (P.nbMoves() + 1) << " \"" << line << "\"" << std::endl;
          }
          else
          {
              std::clock_t start_clock = std::clock();

              double score = solver.solve(P, weak);

              double elapsed = double(clock() - start_clock) / CLOCKS_PER_SEC;

              std::cout << line << " score: " << score << " column: " << solver.getColumn() << " nodes: " << solver.getNodeCount()<<", depth: " << solver.get_depth() << ", elapsed: " << elapsed << " sec, rate: " << solver.getNodeCount() / elapsed << std::endl;;
          }
          std::cout << std::endl;
      }
  }
  


}


