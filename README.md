# Tapestry Algorithm for Distributed Hash Table

This project simulates the following aspects of the tapestry algorithm
for distributed hash tables:

* The network creation (initializing of nodes and their routing tables)
* Addition of a new node into an initialized network (with all the nodes
having their routing tables initialized).

## Instructions

Run the project as:

```
$ mix run tapestry.exs <num_nodes> <num_requests>
```

`num_nodes` is the number of nodes in the network.
- Initially, a network with `num_nodes - 1` nodes is created and their routing tables
are populated.
- Then, another node is added to the network. This introduces modifications
to the routing tables of the older nodes in the network.

`num_requests` is the number of requests each node makes. These requests are to other
random nodes in the network and are sent after a time delay. The time delay is set
in the key `:delay_between_reqs` of the `:tapestry` application in `config/config.exs`.
The **default** time delay between requests from a node is **1000 ms**. The runtime of
the program for larger number of requests can be reduced by reducing this value.

To see a detailed explanation, the log level can be set to `:debug` in `config/config.exs`.
When the log level is set to debug, the path each request has taken from the source to the
the destination is printed.

For example (with the log level set to debug - `config :logger, level: :debug` in `config/config.exs`)

```
$ mix run tapestry.exs 20 2

13:32:59.664 [debug] Done in 1 hop(s), path = 2DA1E257A1DD524E9EB75C522FF74F521BCFEC47 -> D3978C883E77D19C5C34766C3E29EA1BF2CD0A58

13:32:59.664 [debug] Done in 1 hop(s), path = 40F636634A051F40D70310B2334F34C8D572B525 -> 3830B67456CD0D74A6D9322840A1501D36FAB0E1

...

13:33:00.663 [debug] Done in 1 hop(s), path = 2D62C769110E506E997D7037734B4CC085DC3A8A -> 2DA1E257A1DD524E9EB75C522FF74F521BCFEC47

13:33:00.663 [debug] Done in 2 hop(s), path = B3A96A40D40178EE60747517F12DEAC73E35F1AB -> 9D3DBB81B18A9083E6D9CB14C5B0A344E1931075 -> 9972990F0F774E33E6C7E4C77D8A62CA5DC281CC

13:33:00.663 [debug] Done in 2 hop(s), path = C15ED06A821DA5484F22CF949591175F84850FB9 -> 9D3DBB81B18A9083E6D9CB14C5B0A344E1931075 -> 9972990F0F774E33E6C7E4C77D8A62CA5DC281CC
All requests completed. Max hops needed = 2
```

# Description
The project is an implementation of *Tapestry: A Resilient Global-Scale Overlay for Service Deployment by Ben Y. Zhao, Ling Huang, Jeremy Stribling, Sean C. Rhea, Anthony D. Joseph and John D. Kubiatowicz*.

The implementation consists of the following parts:

### Network Creation

In this phase, the routing table for all the nodes is created and set in each of the nodes’ state. Each routing table consists of levels as their rows. These levels are created based on how many digits match between the source node and destination node hashes. As an example, If the first three digits match, then they are placed in the third level of the routing table. The column position is decided according to the first digit mismatch. So, in the above example, the fourth digit will be deciding the column number in the third level. If there is a conflict between two entries for a cell then based on the nearest neighbour logic the node is selected. Nearest neighbour logic works by comparing hashes of each node with source node, and selecting the hash with lesser value as its neighbour. Once all the routing tables are built then the network is considered to be stable.

### Dynamic Node Insertion Algorithm

In our implementation, 1 node is inserted into the network after the network is initialized (all the nodes have built their routing tables) and has become stable. For node insertion following steps are performed:

1. A new node is initialised.
2. Routing table for the new node is built.
3. A multicast call is sent out for all the nearby nodes to make an edit in their routing table. In each routing table, the new node should be entered at a particular cell based on prefix matching and first digit mismatch logic. Once the cell is known, then an entry of the new node is made only if the cell is empty. If the cell is not empty then the entry already present is replaced with the new node based on the nearest neighbour logic.

### Message Routing To Node

For each node, a destination is selected at random and the message passing is started from the source. The source lookups for the destination in its routing table. If the destination is found then the message is received by destination in one hop. If the destination is not present in the routing table then based on prefix matching a node is selected from the source’s routing table and the message is sent to the selected node. The selected node looks for the destination in its own routing table and the same process continues until destination is reached. With each new node hop count is increased by one.

### Output

Output is the maximum number of hops it took to reach from source to destination.

# Result

| # Nodes | # Requests (from each node) | Maximum Hops |
| ------- | --------------------------- | ------------ |
| 100     | 10                          | 4            |
| 100     | 20                          | 3            |
| 500     | 10                          | 4            |
| 500     | 20                          | 4            |
| 1000    | 10                          | 5            |
| 1000    | 20                          | 5            |
| 2000    | 10                          | 5            |
| 2000    | 20                          | 5            |
| 5000    | 10                          | 6            |
| 5000    | 20                          | 6            |
