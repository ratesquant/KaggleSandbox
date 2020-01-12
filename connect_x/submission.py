def my_agent(observation, configuration):
    #print([c for c in range(configuration.columns) if observation.board[c + configuration.columns*(configuration.rows-1)] == 0])
    from random import choice
    return choice([c for c in range(configuration.columns) if observation.board[c] == 0])
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns

    # Due to compute/time constraints the tree depth must be limited.
    max_depth = 7
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size + 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:
               return (beta,None)  # prune the exploration if the [alpha;beta] window is empty.               

        # Recursively check all columns.
        best_score = -size
        best_column = None
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1     
                    
                    if score >= beta: 
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only       
                    
                if score > best_score:
                    best_score = score
                    best_column = column        
        return (best_score, best_column)

    _, column = negamax(obs.board[:], obs.mark, max_depth, -1000, 1000)
    if column == None:
        print('do we ever get here')
        column = choice([c for c in range(columns) if obs.board[c] == 0])
    return column
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns

    # Due to compute/time constraints the tree depth must be limited.
    max_depth = min(50, size - sum(1 if cell != 0 else 0 for cell in obs.board[:]))    
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size + 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:
               return (beta,None)  # prune the exploration if the [alpha;beta] window is empty.               

        # Recursively check all columns.
        best_score = -size
        best_column = None
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                    
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only       
                    
                if score > best_score:
                    best_score = score
                    best_column = column
                    
#                if depth == max_depth: 
#                    print('move %s, %s, %s, %s'%(column, score, best_column, best_score))
                    
        return (best_score, best_column)

    _, column = negamax(obs.board[:], obs.mark, max_depth, -1000, 1000)
    if column == None:        
        column = choice([c for c in range(columns) if obs.board[c] == 0])
    return column
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns

    # Due to compute/time constraints the tree depth must be limited.
    max_depth = min(50, size - sum(1 if cell != 0 else 0 for cell in obs.board[:]))    
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size + 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:
               return (beta,None)  # prune the exploration if the [alpha;beta] window is empty.               

        # Recursively check all columns.
        best_score = -size
        best_column = None
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                    
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only       
                    
                if score > best_score:
                    best_score = score
                    best_column = column
                    
#                if depth == max_depth: 
#                    print('move %s, %s, %s, %s'%(column, score, best_column, best_score))
                    
        return (best_score, best_column)

    _, column = negamax(obs.board[:], obs.mark, max_depth, -1000, 1000)
    if column == None:        
        column = choice([c for c in range(columns) if obs.board[c] == 0])
    return column
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns
    calls = 0 

    # Due to compute/time constraints the tree depth must be limited.
    max_depth = min(8*columns, size - sum(1 if cell != 0 else 0 for cell in obs.board[:]))    
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):        
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size + 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:               
               return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.               

        # Recursively check all columns.        
        best_score = -size
        best_column = None
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0: 
                    #we dont ever get here
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only                                               
                    
                if score > best_score:
                    best_score = score
                    best_column = column        
        #return (best_score, best_column)
        return (alpha, best_column)

    best_score, best_column = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns
    calls = 0 

    # Due to compute/time constraints the tree depth must be limited.    
    max_depth = 9
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):        
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:               
               return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.               
            
        if depth == max_depth:
            all_moves = []
            for column in range(columns):
                if board[column] == 0:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    score = score * -1
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only    
                    all_moves.append((column, score))
            return (all_moves)
            

        # Recursively check all columns.                
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                     
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only                                               
        return (alpha, column)

    all_moves = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
    
    if isinstance(all_moves, list):
        best_score = max([score for col, score in all_moves])
        best_column = choice([col for col, score in all_moves if score>=best_score])
        #best_column = [col for col, score in all_moves if score>=best_score][0]
    else:
        best_score, best_column = all_moves
    
    #print(obs.mark, all_moves, best_score, best_column)
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column
def negamax_agent(obs, config):
    from random import choice
    columns = config.columns
    rows = config.rows
    size = rows * columns
    calls = 0 

    # Due to compute/time constraints the tree depth must be limited.    
    max_depth = 9
    
    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1
        row = (
            min([r for r in range(rows) if board[column + (r * columns)] == mark])
            if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
        )
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
    
        return (
            count(1, 0) >= inarow  # vertical.
            or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
            or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
            or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
        )

    def negamax(board, mark, depth, alpha, beta):        
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:               
               return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.               
            
        if depth == max_depth:
            all_moves = []
            for column in range(columns):
                if board[column] == 0:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    score = score * -1
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only    
                    all_moves.append((column, score))
            return (all_moves)
            

        # Recursively check all columns.                
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                     
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only                                               
        return (alpha, column)

    all_moves = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
    
    if isinstance(all_moves, list):
        best_score = max([score for col, score in all_moves])
        best_column = choice([col for col, score in all_moves if score>=best_score])
        #best_column = [col for col, score in all_moves if score>=best_score][0]
    else:
        best_score, best_column = all_moves
    
    #print(obs.mark, all_moves, best_score, best_column)
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column
