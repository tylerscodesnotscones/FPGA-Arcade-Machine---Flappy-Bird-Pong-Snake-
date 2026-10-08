# FPGA-Arcade-Machine---Flappy-Bird-Pong-Snake-
Temporary Desc. - Arcade Machine Emulator using the Artix-7 Basys3 FPGA Board to program hardware using vivado software. Excecuted with an external monitor connected by a VGA cable

PROPOSAL
FPGA Arcade Machine
Project Description *
What the system does, its inputs and outputs, the main features, and how a user interacts with it on the Basys 3 board (switches, buttons, seven-segment display, LEDs, VGA, and so on).
What the system does / main features: The system is an FPGA arcade cabinet simulator that holds 3 games, Snake, Pong, and Flappy Bird. The system will manage everything, including state machine transitions, menu navigation, collision detection, graphic rendering, and score systems.
Inputs: Onboard buttons (btnU, btnD, btnL, btnR, btnC), 100MHz clock, 
Outputs: Seven segment display (Score counter), VGA outputs 640x480 @ 60 Hz to an external monitor
Facets of Interaction: 
1.	At launch, the user is prompted by a screen to choose which of the three games they will pick. The user can navigate this menu using btnU / btnD, and choosing with btnC.
2.	During Flappy Bird, the user can move the bird up by pressing btnU.
During Snake, the user can maneuver the snake by using the 4 directional buttons (up, down, left, right).
3.	During Pong, the user can manipulate the board to hit the pong using the up and down buttons.
4.	During all games, pressing the btnC will return the user to the menu.
FPGA justification *
Explain why an FPGA is the right choice for this design rather than a general-purpose processor or a software solution. A strong justification points to properties such as true parallelism, deterministic real-time behavior, custom digital logic, or direct control of I/O timing. This section should convince the reader that your project genuinely benefits from reconfigurable hardware.
Prototyping
And low latency
Application-Specific Integrated Circuits (ASIC) for custom digital hardware allows for low production cost when manufacturing thousands or millions of boards, but it is permanent and is unable to be used well to prototype a system. Utilizing an FPGA like the Basys 3 provides an ideal prototyping environment, perfect for simulating the early stages of an arcade machine before mass production. By implementing the entire logic architecture in reconfigurable hardware, it can be validated & debugged immediately, without having to go through the ASIC design process again.
Unlike software systems that process things sequentially, FPGAs utilizes parallel hardware, meaning game physics, menu navigation, and VGA signal gen process every clock cycle. Because hardware logic updates states instantly on clock edges, frame stuttering is reduced to zero, and input lag due to software is as well. The only sources of input lag are the button debounce and the refresh rate of the monitor.
lab report https://docs.google.com/document/d/18-R9KQJNORR-_sd9KY3DB34fzjNnRAeBUAXGukc47DQ/edit?usp=sharing
