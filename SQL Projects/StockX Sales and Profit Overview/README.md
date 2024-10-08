# _StockX_: Sales and Profit Overview

_StockX_ is an online retail site where users can buy and sell their items and operates like an auction house and stock market. Customers can place bids on an item and sellers may choose to accept it based on the current market value. The site keeps track of all sales for both parties to consider before pursuing a deal. Although the site primarily focuses on sneakers, it has expanded to clothing and accessories related to the streetwear culture.

In February 2019, _StockX_ held a contest for data-enthusiasts to come up with any interesting insights based on sales data from September 2017 to February 2019. The data they provided included nearly 100,000 transactions of Yeezy and Off-White sneakers in the United States. Winners were entitled to a t-shirt, with first place receiving $1000 in site credit. Unfortunately, I am over four years late to the contest, but as someone who has grown up around sneaker and streetwear culture since childhood, the data is very interesting. For this analysis, I use PostgreSQL to explore some standard sales and profit information based on region/state, time, and sneaker brand, model, colourway, and size.

## Data

The data was provided by [_StockX_](https://stockx.com/news/the-2019-data-contest/). In order to utilize and explore it in PostgreSQL, the dates, sale and retail price, and shoe sizes had to be formatted on Excel and then imported into a table.
