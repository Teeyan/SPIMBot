# syscall constants
PRINT_STRING	= 4
PRINT_CHAR	= 11
PRINT_INT	= 1

# memory-mapped I/O
VELOCITY	= 0xffff0010
ANGLE		= 0xffff0014
ANGLE_CONTROL	= 0xffff0018

BOT_X		= 0xffff0020
BOT_Y		= 0xffff0024

TIMER		= 0xffff001c

TILE_SCAN	= 0xffff0024
HARVEST_TILE	= 0xffff0020

GET_FIRE_LOC	= 0xffff0028
PUT_OUT_FIRE	= 0xffff0040

PRINT_INT_ADDR		= 0xffff0080
PRINT_FLOAT_ADDR	= 0xffff0084
PRINT_HEX_ADDR		= 0xffff0088

# interrupt constants
BONK_MASK	= 0x1000
BONK_ACK	= 0xffff0060

TIMER_MASK	= 0x8000
TIMER_ACK	= 0xffff006c

ON_FIRE_MASK	= 0x400
ON_FIRE_ACK	= 0xffff0050


.data
# put your data things here

.align 2

numPlants: .word 0		# CURRENT number of plants to be harvested

tiles: .space 1600	#stores all tiles

poolantsX: .space 40		#stores x values 
poolantsY: .space 40		#stores y values

.text
main:
	# put your code here :)
	
	#store tile information into array dead_inside
updoot:

	la $t0, tiles
	sw $t0, TILE_SCAN


	#search for a plant and store its location data
scan:
	li $t1, 0		# $t1 = int i = 0	

scan_for: 

	bge $t1, 100, prep_harvest

	#if conditional to check if current tile (i) is a growing tile or nah
	move $t2, $t0
	li $t3, 16
	mult $t1, $t3
	mflo $t3
	add $t2, $t2, $t3
	lw $t4, 0($t2)			#$t4 = tile[i]

	bne $t4, 1, scan_if_break
	
	#push growing tile's midpoint x into the growing tiles x array
	la $t2, poolantsX
	lw $t3, numPlants
	li $t4, 4
	mult $t3, $t4
	mflo $t4
	add $t2, $t2, $t4
	#x-value = (i%10)*30 + 15
	li $t5, 10
	div $t1, $t5
	mfhi $t5
	li $t6, 30
	mult $t5,$t6
	mflo $t5
	add $t5, $t5, 15		
	sw $t5, 0($t2)			#poolants[x] = x-coord
	
	#push growing tile's midpoint y into the growing tiles y array
	la $t2, poolantsY
	li $t4, 4
	mult $t3, $t4
	mflo $t4
	add $t2, $t2, $t4
	#y-value = (i/10)*30 + 15
	li $t5, 10
	div $t1, $t5
	mflo $t5
	li $t6, 30
	mult $t5, $t6
	mflo $t5
	add $t5, $t5, 14
	sw $t5, 0($t2)

	add $t3, $t3, 1
	sw $t3, numPlants 		#increment the size of numPlants by 1

scan_if_break:
	
	add $t1, $t1, 1
	j scan_for	
	
####################################################################################################################
#Begin actual harvesting


	## begin harvesting of growing plant tiles - can use any t register except t0

prep_harvest:

	## start preparations for harvesting plants, i.e. set up the for loop and other relevant vars.
	li $t1, 0			#$t1 = int i = 0, counter for which plant we are on
	lw $t2, numPlants		#$t2 = numPlants

start_harvest:
	#for loop to harvest all 10 plants
	bge $t1, $t2, end_harvest

	#move SPIMBot to the x coordinate of the plant

	lw $t3, BOT_X			# $t3 = bots current x val
	la $t4, poolantsX		# $t4 = get pointer to first value of poolants
	li $t5, 4
	mult $t5, $t1
	mflo $t5
	add $t4, $t4, $t5
	lw $t4, 0($t4)			# $t4 = target x-value

#handles if bot is already at correct x coord
x_equal:
	beq $t3, $t4, y_set
	
#handles if x is greater than target
x_greater:
	blt $t3, $t4, x_lesser 
	li $t5, 180
	sw $t5, ANGLE
	li $t5, 1
	sw $t5, ANGLE_CONTROL		# turns SPIMBot to the left
	li $t5, 5
	sw $t5, VELOCITY		# drive
	
	j x_move

#handles if x is lesser than target
x_lesser:	
	bgt $t3, $t4, x_move
	li $t5, 0
	sw $t5, ANGLE
	li $t5, 1
	sw $t5, ANGLE_CONTROL		#turns SPIMBot to the right
	li $t5, 5
	sw $t5, VELOCITY		#drive

	j x_move

x_move:
	lw $t3, BOT_X
	sub $t3, $t3, $t4
	abs $t3, $t3

	#bne $t3, $t4, x_move
	bgt $t3, 3, x_move	
	li $t5, 0
	sw $t5, VELOCITY	

y_set:
	# move SPIMbot to y-coord

	lw $t3, BOT_Y			#$t3 = bots current y-val
	la $t4, poolantsY		# $t4 = point to current plant location
	li $t5, 4
	mult $t5, $t1
	mflo $t5
	add $t4, $t4, $t5
	lw $t4, 0($t4)			#$t4 = target y-value

#handles if bot is already at correct y coord
y_equal:
	beq $t3, $t4, harvest

y_greater: 
	blt $t3, $t4, y_lesser
	li $t5, -90
	sw $t5, ANGLE
	li $t5, 1
	sw $t5, ANGLE_CONTROL		# turns SPIMBot to the left
	li $t5, 5
	sw $t5, VELOCITY		# drive
	
	j y_move

y_lesser:
	bgt $t4, $t4, y_move
	li $t5, 90
	sw $t5, ANGLE
	li $t5, 1
	sw $t5, ANGLE_CONTROL		#turns SPIMBot to the right
	li $t5, 5
	sw $t5, VELOCITY		#drive

	j y_move

y_move:
	lw $t3, BOT_Y
	sub $t3, $t3, $t4
	abs $t3, $t3

	#bne $t3, $t4, y_move
	bgt $t3, 3, y_move
	li $t5, 0
	sw $t5, VELOCITY
	

harvest:
	#harvest tile then continue through loop
	sw $zero, HARVEST_TILE
	add $t1, $t1, 1
	j start_harvest
		
end_harvest:
	#harvested all plants, infinite loop until SPIMbot degenerates into the warm embrace of death
	j updoot

#####################################
