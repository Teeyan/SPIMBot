# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

TILE_SCAN       = 0xffff0024
SEED_TILE       = 0xffff0054
WATER_TILE      = 0xffff002c
MAX_GROWTH_TILE = 0xffff0030
HARVEST_TILE    = 0xffff0020
BURN_TILE       = 0xffff0058
GET_FIRE_LOC    = 0xffff0028
PUT_OUT_FIRE    = 0xffff0040

GET_NUM_WATER_DROPS   = 0xffff0044
GET_NUM_SEEDS         = 0xffff0048
GET_NUM_FIRE_STARTERS = 0xffff004c
SET_RESOURCE_TYPE     = 0xffff00dc
REQUEST_PUZZLE        = 0xffff00d0
SUBMIT_SOLUTION       = 0xffff00d4

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
ON_FIRE_MASK            = 0x400
ON_FIRE_ACK             = 0xffff0050
MAX_GROWTH_ACK          = 0xffff005c
MAX_GROWTH_INT_MASK     = 0x2000
REQUEST_PUZZLE_ACK      = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

.data
# data things go here

#boolean to decide if it burns everything to the ground (initially set to 0)
lol420xd: .word 0

#space for array of tiles
tiles: .space 1600
#space for puzzle struct
puzzle: .space 4096
#space for puzzle solution
solution: .space 328

###Variables for movement

#x location to move to
x: .word 0
y: .word 0

.text
main:
	# go wild
	# the world is your oyster :)

#################SET UP###########################################

	#Enable Interrupts
	li	$t4, TIMER_MASK		# timer interrupt enable bit
	or	$t4, $t4, BONK_MASK	# bonk interrupt bit
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)

	#Store TILE Information into array tiles
	la $t0, tiles
	sw $t0, TILE_SCAN
	
	j seeding

	#Move to Position 0,0
###############Helper Functions####################
update:
	la $t0, tiles
	sw $t0, TILE_SCAN

########Move#################
move_bot:
	#move SPIMBot to the x coordinate of the plant
	lw $t0, BOT_X				
	lw $t1, x

#handles if bot is already at correct x coord
x_equal:
	beq $t0, $t1, y_set
	
#handles if x is greater than target
x_greater:
	blt $t0, $t1, x_lesser 
	li $t2, 180
	sw $t2, ANGLE
	li $t2, 1
	sw $t2, ANGLE_CONTROL		# turns SPIMBot to the left
	li $t2, 7
	sw $t2, VELOCITY		# drive
	
	j x_move

#handles if x is lesser than target
x_lesser:	
	bgt $t0, $t1, x_move
	li $t2, 0
	sw $t2, ANGLE
	li $t2, 1
	sw $t2, ANGLE_CONTROL		#turns SPIMBot to the right
	li $t2, 7
	sw $t2, VELOCITY		#drive

	j x_move

x_move:
	lw $t0, BOT_X
	sub $t0, $t0, $t1
	abs $t0, $t0

	#bne $t3, $t4, x_move
	bgt $t0, 3, x_move	
	li $t2, 0
	sw $t2, VELOCITY	

y_set:
	# move SPIMbot to y-coord
	lw $t0, BOT_Y			
	lw $t1, y

#handles if bot is already at correct y coord
y_equal:
	beq $t0, $t1, arrival

y_greater: 
	blt $t0, $t1, y_lesser
	li $t2, -90
	sw $t2, ANGLE
	li $t2, 1
	sw $t2, ANGLE_CONTROL		# turns SPIMBot to the left
	li $t2, 7
	sw $t2, VELOCITY		# drive
	
	j y_move

y_lesser:
	bgt $t0, $t1, y_move
	li $t2, 90
	sw $t2, ANGLE
	li $t2, 1
	sw $t2, ANGLE_CONTROL		#turns SPIMBot to the right
	li $t2, 7
	sw $t2, VELOCITY		#drive

	j y_move

y_move:
	lw $t0, BOT_Y
	sub $t0, $t0, $t1
	abs $t0, $t0

	#bne $t3, $t4, y_move
	bgt $t0, 3, y_move
	li $t2, 0
	sw $t2, VELOCITY

arrival:
	jr $ra

#############Base Bot Code#########################################

###Process of seeding the tiles
seeding:

	#when seeding get water from the puzzle
	#li $t0, 0
	#sw $t0, SET_RESOURCE_TYPE

	#If the number of seeds is not 0 continue seeding
	lw $t0, GET_NUM_SEEDS
	beq $t0, 0, watering

	la $t0, tiles
	sw $t0, TILE_SCAN

	#Find the first empty tile available for seeding - $t0 is the tiles array
	li $t1, 0		#counter

seed_scan:
	#if the tile is empty proceed to seed it if not keep looking
	lw $t2, 0($t0)
	beq $t2, 0, seed
	beq $t1, 100, watering	#move on to watering if all tiles are seeded
	add $t1, $t1, 1
	add $t0, $t0, 16
	j seed_scan
	
seed:
	#get the x and y value of the midpoint of the tile that is unseeded ($t1 holds tile number)
	li $t2, 10
	div $t1, $t2
	mfhi $t2
	li $t3, 30
	mult $t2, $t3
	mflo $t2
	add $t2, $t2, 15
	sw $t2, x

	li $2, 10
	div $t1, $t2
	mfhi $t2
	li $t3, 30
	mult $t2, $t3
	mflo $t2
	add $t2, $t2, 15
	sw $t2, y

	#move to the proper location
	jal move_bot
	
	#Seed tile
	sw $0, SEED_TILE 
	
	j seeding
	

###Process of watering the tiles
watering:
	j end

	lw $t0, GET_NUM_WATER_DROPS
	beq $t0, 0, harvesting

###Process of harvesting the tiles
harvesting:


#######LOOP FOR TESTING#######################
end:
	j end
#############Interrupt Handler######################################

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 8	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   

	and	$a0, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt

	# add dispatch for other interrupt types here.

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

bonk_interrupt:
	sw	$a1, BONK_ACK		# acknowledge interrupt
	sw	$zero, VELOCITY		# ???

	j	interrupt_dispatch	# see if other interrupts are waiting

timer_interrupt:
	sw	$a1, TIMER_ACK		# acknowledge interrupt

	li	$t0, 90			# ???
	sw	$t0, ANGLE		# ???
	sw	$zero, ANGLE_CONTROL	# ???

	lw	$v0, TIMER		# current time
	add	$v0, $v0, 50000  
	sw	$v0, TIMER		# request timer in 50000 cycles

	j	interrupt_dispatch	# see if other interrupts are waiting

non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
