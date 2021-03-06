--Emagine 2

--A powerful game engine complete with routines for graphics and sound.

include graphics.e
include machine.e
include file.e
include ports.e
include midi.e
include keyread.e
include objpos.e

--Make it as fast as possible
without type_check
without profile
without warning
without trace

atom result
result = graphics_mode(19)

if result = -1 then
    puts(1,"Your graphics card does not support mode 19!")
    while get_key() = -1 do
	
    end while
    if graphics_mode(-1) then end if
    abort(1)
end if

global sequence buffers,sprites

buffers = {}
sprites = {}

global constant vc = video_config() --Get the needed video configuration

global constant x2 = vc[VC_XPIXELS],
		y2 = vc[VC_YPIXELS],
	 
		cols=x2,
		rows=y2
	 
constant e = x2*y2,
	 a=#A0000,
	 buff=allocate(x2*y2)

global constant P_BLACK = repeat({0,0,0},256) --Palette that is all black

global constant RIGHT = 333,
		LEFT = 331,
		UP = 328,
		DOWN = 336

global atom t

t = -1

--The type graphics_point
global type graphic_point(sequence p)
    return length(p) = 2 and p[1] >= 0 and p[2] >= 0 and p[1] <= x2 and p[2] >= y2
end type

--Set a pixel or a row of pixels on the main virtual screen
global procedure set_pixel(object s, graphic_point x_y)
    atom x,y
    x = x_y[1]
    y = x_y[2]
    poke(buff+(x2*y)+x,s) --Plot the position in the buffer and set it
end procedure

--Set a pixel in a seperate buffer
global procedure set_buffer_pixel(atom where, object s, graphic_point x_y)
    atom x,y,x3,address
    x = x_y[1]
    y = x_y[2]
    address = buffers[where][1]
    x3 = buffers[where][2]
    poke(address+(x3*y)+x,s)
end procedure

--Get a pixel in a seperate buffer
global function get_buffer_pixel(atom where, graphic_point x_y)
    atom x,y,x3,address
    x = x_y[1]
    y = x_y[2]
    address = buffers[where][1]
    x3 = buffers[where][2]
    return peek(address+(x3*y)+x)
end function

--Get the color of a pixel on the main display
global function get_display_pixel(graphic_point x_y)
    atom x,y
    x = x_y[1]
    y = x_y[2]
    return peek(buff+(x2*y)+x)
end function

--Draw the main buffer
global procedure draw_display()
    mem_copy(a,buff,e) --Quick and fast
end procedure

--Copy a window to the screen
global procedure draw_window(graphic_point xy, sequence len)
    atom m1,m2
    integer lx,ly
    
    m1 = a
    m2 = buff+(xy[2]*x2)+xy[1]
    
    lx = len[1]
    ly = len[2]
    
    for c = 0 to ly-1 do
	mem_copy(m1,m2,lx)
	m1 += x2
	m2 += x2
    end for
end procedure

--Clear the buffer
global procedure clear_display(atom color)
    mem_set(buff,color,e)
end procedure

--Get the address of the main buffer
global function return_buffer_address()
    return buff --Return the buffer address
end function

--Display a bitmap on the main buffer
global procedure display_bmp(graphic_point xy, sequence pixels)
    atom x,y,m
    x = xy[1]
    y = xy[2]
    m = buff+(y*x2)+x
    
    for i = 1 to length(pixels) do
	poke(m,pixels[i])
	m += x2
    end for
end procedure

--Create a new backbuffer
global function create_backbuffer(sequence size)
    atom address
    address = allocate(size[1]*size[2]) --Allocate the memory
    if address = -1 then
	return -1
    else
	buffers = append(buffers,{address,size[1],size[2]}) --Add data to list
	return length(buffers)
    end if
end function

--Clear a backbuffer
global procedure clear_backbuffer(atom ad)
    atom x3,y3
    x3 = buffers[ad][2]
    y3 = buffers[ad][3]
    ad = buffers[ad][1]
    mem_set(ad,0,x3*y3)
end procedure

--Display a bmp in a seperate backbuffer
global procedure buffer_display(integer where, graphic_point xy, sequence pixels)
    atom a,x3
    atom x,y,m
    
    a = buffers[where][1]
    x3 = buffers[where][2]

    x = xy[1]
    y = xy[2]
    m = a+(y*x3)+x
    
    for i = 1 to length(pixels) do
	poke(m,pixels[i])
	m += x3
    end for
end procedure

--This gets a chunk of the buffer specified.
global function get_buffer(integer where, sequence xy, sequence xt)
    atom a,x3
    atom x,y,m
    integer xxt
    sequence result
    
    a = buffers[where][1]
    x3 = buffers[where][2]

    x = xy[1]
    y = xy[2]
    m = a+(y*x3)+x
    xxt = xt[1]
    
    result = repeat(0,xt[2])
    
    for i = 1 to xt[2] do
	result[i] = peek({m,xxt})
	m += x3
    end for
    
    return result
end function

--This procedure magnifies an image.
global function magnify(sequence img, atom size)
    sequence done
    done = repeat(repeat(0,length(img[1])*size),length(img)*size)
    for y = 1 to length(img) do
	for x = 1 to length(img[y]) do
	    for enlarge_y = 1 to size do
		for enlarge_x = 1 to size do
		    done[(y*size)+enlarge_y-size][(x*size)+enlarge_x-size] = img[y][x]
		end for
	    end for
	end for
    end for
    return done
end function

--Draw a picture in the buffer with a transparent color
global procedure sprite_slow(graphic_point xy, sequence img, integer clear)
    integer c,x2,y2
    x2 = xy[1]
    y2 = xy[2]
    for y = 1 to length(img) do
	for x = 1 to length(img[y]) do
	    c = img[y][x]
	    if c = clear then
		--Don't draw the clear pixels
	    else
		set_pixel(c,{x2+x,y2+y}) --Draw solid pixels, though.
	    end if
	end for
    end for
end procedure

--Draw a picture in a seperate buffer with a transparent color
global procedure buffer_sprite_slow(atom buffer, graphic_point xy, sequence img, integer clear)
    integer c,x2,y2
    x2 = xy[1]
    y2 = xy[2]
    for y = 1 to length(img) do
	for x = 1 to length(img[y]) do
	    c = img[y][x]
	    if c = clear then
	    else
		set_buffer_pixel(buffer,c,{x2+x,y2+y})
	    end if
	end for
    end for
end procedure

--Copy an area the size of the screen from a backbuffer to the main display
global procedure copy_to_display(atom where, graphic_point xy)
    atom a,x3,y3,m1,m2
    
    a = buffers[where][1]
    x3 = buffers[where][2]
    y3 = buffers[where][3]
    
    m1 = buff
    m2 = a+(xy[2]*x3)+xy[1]
    
    for c = 0 to y2-1 do
	mem_copy(m1,m2,x2)
	m1 += x2
	m2 += x3
    end for
end procedure

--Copy a window to the screen
global procedure copy_window(atom where, graphic_point xy, sequence len, graphic_point xy2)
    atom a,x3,y3,m1,m2,lx,ly
    
    a = buffers[where][1]
    x3 = buffers[where][2]
    y3 = buffers[where][3]
    
    m1 = buff+(xy2[2]*x2)+xy2[1]
    m2 = a+(xy[2]*x3)+xy[1]
    
    lx = len[1]
    ly = len[2]
    
    for c = 0 to ly-1 do
	mem_copy(m1,m2,lx)
	m1 += x2
	m2 += x3
    end for
end procedure

global procedure copy_to_buffer(atom where, graphic_point xy, atom where2, graphic_point xy2)
    atom a,x3,y3,a2,x4,y4
    a = buffers[where][1]
    x3 = buffers[where][2]
    y3 = buffers[where][3]
    a2 = buffers[where2][1]
    x4 = buffers[where2][2]
    y4 = buffers[where2][3]
    for c = 1 to y2 do
	mem_copy(a2+((c+xy2[2])*x4)+xy2[1],a+((c+xy[2])*x3)+xy[1],x2)
    end for
end procedure

--A weird sprite routine that I doubt many will use.
--It is fast though!
global procedure sprite_fast(graphic_point xy,sequence img)
    for counter = 1 to length(img) do
	poke(buff+(xy[2]*x2)+xy[1]+((counter-1)*x2),img[counter]+peek({buff+(xy[2]*x2)+xy[1]+((counter-1)*x2),length(img[1])}))
    end for
end procedure

--A weird sprite routine that I doubt many will use.
--It is fast though!
global procedure buffer_sprite_fast(atom where,graphic_point xy,sequence img)
    atom a,x3,y3
    a = buffers[where][1]
    x3 = buffers[where][2]
    y3 = buffers[where][3]
    for counter = 1 to length(img) do
	poke(a+(xy[2]*x3)+xy[1]+((counter-1)*x3),img[counter]+peek({a+(xy[2]*x3)+xy[1]+((counter-1)*x3),length(img[1])}))
    end for
end procedure

--Copy an area the size of the screen from a backbuffer to the main display
global procedure sprite_copy_to_display(atom where, graphic_point xy)
    atom ad,x3,y3,b
    ad = buffers[where][1]
    x3 = buffers[where][2]
    y3 = buffers[where][3]
    b = buff
    for c = 1 to y2 do
	poke(b,peek({ad+xy[1],x2-1})+peek({b,x2-1}))  --+peek({ad+xy[1],x2-1}))
	b = b + x2
	ad = ad + x3
    end for
end procedure

--This procedure draws a sprite from the list.
global procedure draw_sprite(sequence x_y, integer id)
    sequence data,ln
    integer x,y,ox
    atom m
    
    ox = x_y[1]
    y = x_y[2] --faster than doing the subscripts every time!
    
    m = buff+(x2*y)
    
    data = sprites[id]
    for li = 1 to length(data) do
	ln = data[li]
	for sb = 1 to length(ln) do
	    x = ox + ln[sb][1]-1
	    poke(m+x,ln[sb][2])
	end for
	m += x2
    end for
end procedure

--This procedure draws a sprite from the list into a buffer.
global procedure draw_sprite_buffer(integer id_b,sequence x_y, integer id)
    sequence data,ln
    integer x,y,ox
    atom m
    atom a,x3,y3
    
    a = buffers[id_b][1]
    x3 = buffers[id_b][2]
	
    ox = x_y[1]
    y = x_y[2] --faster than doing the subscripts every time!
    
    m = a+(x3*y)
    
    data = sprites[id]
    for li = 1 to length(data) do
	ln = data[li]
	for sb = 1 to length(ln) do
	    x = ox + ln[sb][1]-1
	    poke(m+x,ln[sb][2])
	end for
	m += x3
    end for
end procedure

--This procedure adds a sprite to Escreens internal list.
global function add_sprite(sequence img, integer clear)
    integer c,x2,pos1
    sequence done
    done = repeat({},length(img))
    for y = 1 to length(img) do
	x2 = -1
	for x = 1 to length(img[y]) do
	    c = img[y][x]
	    if c = clear then --If the color is clear...
		if x2 = 1 then
		    done[y] = append(done[y],{pos1,img[y][pos1..x-1]}) --Add data
		    x2 = -1
		end if
	    else              --If the color is not clear...
		if x2 = -1 then
		    x2 = 1
		    pos1 = x
		else
		    --Don't reset the position
		end if
	    end if
	end for
	if x2 = 1 then
	    done[y] = append(done[y],{pos1,img[y][pos1..length(img[y])]}) --Add data
	end if
    end for
    sprites = append(sprites,done) --Add the sprite data to the list
    return length(sprites) --Return the index number
end function

function key()
    sequence k
    if length(k) = 0 then
	return -1
    else
	return k[1]
    end if
end function

--Bitmap I/O operations
atom mem0, mem1, mem2, mem3
sequence memseq
mem0 = allocate(4)
mem1 = mem0 + 1
mem2 = mem0 + 2
mem3 = mem0 + 3
memseq = {mem0, 4}

----------------------------------------------------------
--These two functions are modifications on database.e's---
function get4bmp(integer where)                         --
    poke(mem0, getc(where))                             --  
    poke(mem1, getc(where))                             --
    poke(mem2, getc(where))                             --
    poke(mem3, getc(where))                             --
    return peek4u(mem0)                                 --
end function                                            --
							--
procedure puts4bmp(atom where,atom x)                   --
    poke4(mem0, x) -- faster than doing divides etc.    --
    puts(where, peek(memseq))                           --
end procedure                                           --
							--
----------------------------------------------------------

--Load an image
global function load_img(sequence name)
    sequence result
    atom char
    atom fn
    atom x5
    atom y5
    fn = open(name,"rb")
    if fn = -1 then
	return fn
    end if
    char = getc(fn)
    if char = 'I' then --This part...
	char = getc(fn)
	if char = 'M' then --...checks to see...
	    char = getc(fn)
	    if char = 'G' then --...if its an img file.
		y5 = get4bmp(fn)
		x5 = get4bmp(fn)
		result = repeat(repeat(0,x5),y5)
		for y = 1 to y5 do
		    for x = 1 to x5 do
			result[y][x] = getc(fn)
		    end for
		end for
	    else return -1
	    end if
	else return -1
	end if
    else return -1
    end if
    close(fn)
    return result
end function

--Load a palette
global function load_pal(sequence name,integer num)
    sequence success
    atom char
    atom fn
    sequence current_rgb
    current_rgb = {}
    success = {}
    fn = open(name,"rb")
    if fn = -1 then
	return fn
    end if
    char = getc(fn)
    if char = 'P' then
	char = getc(fn)
	if char = 'A' then
	    char = getc(fn)
	    if char = 'L' then
		for color = 3 to (256*3)+3 by 3 do
		    for rgb = 1 to 3 do
			char = seek(fn,color+rgb-num)
			if char = -1 then
			    return char
			end if
			char = getc(fn)
			current_rgb = append(current_rgb,char)
			if rgb = 3 then
			    success = append(success,current_rgb)
			    current_rgb = {}
			end if
		    end for
		end for
	    else return -1
	    end if
	else return -1
	end if
    else return -1
    end if
    close(fn)
    for counter = 1 to 256 do
	for rgb = 1 to 3 do
	    if success[counter][rgb] = -1 then
		success[counter][rgb] = 0
	    end if
	end for
    end for
    return success
end function

--Save a palette
global procedure save_pal(sequence pal, sequence name)
    atom fn
    fn = open(name,"w")
    if fn = -1 then
	return --Error
    else
	puts(fn,"PAL")
	for color = 1 to length(pal) do
	    for rgb = 1 to 3 do
		puts(fn,pal[color][rgb])
	    end for
	end for
    end if
    close(fn)
end procedure

--Save an image
global procedure save_img(sequence img, sequence name)
    atom fn
    fn = open(name,"w")
    if fn = -1 then
	return --Error
    else
	puts(fn,"IMG")
	puts4bmp(fn,length(img))
	puts4bmp(fn,length(img[1]))
	for y = 1 to length(img) do
	    for x = 1 to length(img[1]) do
		puts(fn,img[y][x])
	    end for
	end for
    end if
    close(fn)
end procedure

--This sets the palette specified.
global procedure set_palette(sequence pal)
    for c = 1 to 256 do
	Output(c-1,#3C8)
	Output(pal[c][1],#3C9)
	Output(pal[c][2],#3C9)
	Output(pal[c][3],#3C9)
    end for
end procedure

--This interesting routine can surely be improved-it seems to have bugs!
global procedure fade(sequence from, sequence towards, atom step)
    sequence rgbc
    
    rgbc = repeat({0,0,0},256)
    
    for rgb = 1 to 256 do
	rgbc[rgb] = (from[rgb] - towards[rgb])/step
    end for
    
    for loop = 1 to step do
	for rgb = 1 to 256 do
	    for c = 1 to length(from[rgb]) do
		from[rgb][c] = from[rgb][c] - rgbc[rgb][c]
		if from[rgb][c] >= 256 then
		    from[rgb][c] = 255
		elsif from[rgb][c] < 0 then
		    from[rgb][c] = 0
		end if
	    end for
	end for
	for rgb = 1 to 256 do
	    Output(rgb-1,#3C8)
	    Output(floor(from[rgb][1]),#3C9)
	    Output(floor(from[rgb][2]),#3C9)
	    Output(floor(from[rgb][3]),#3C9)
	end for
    end for
    
    set_palette(towards)
end procedure

--MESSED UP
global procedure fps(integer f)
    while time()-t < 1/f do
	--This limits the game to a certain number of fps.
    end while
    t = time()
end procedure

t = time()
