# Do you have a _Second_?: An NBA Second-Round Draft Analysis

During the 2022-23 NBA season, the trade deadline was quite the spectacle. Star players were dealt and teams in contention for the title made moves to address their needs. To do so, as with nearly all trades, teams provided enough draft picks to satisfy the transactions. However, the interesting part of some of these deals last season were the number of second-round picks teams had to attach to get the trade through. Players like Jae Crowder and Josh Richardson were traded for three or more second-round picks. While the amount of draft compensation for players like these may be suitable, the value of second-round draft picks is historically known for little production. So in this analysis, I use PostgreSQL to explore the 2002-2021 draft classes to take a deeper look into some of the value behind the second-round and see if there is any reason to hoard this many picks.

## Data

Player information and statstics from each year of the NBA Draft was provided by [Basketball Reference](https://www.basketball-reference.com/draft/). Each year was individually downloaded, then merged into one CSV file using Excel.
