module smartlift(/*SW, LED_G, LED_R, HEX0, HEX1, KEY0, CLOCK_50, LCD_DATA, 
				 LCD_EN, LCD_RS, LCD_RW, LCD_ON, LCD_BLON*/
				 output	[7:0]	LCD_DATA, //entrada do lcd
				 output	LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON, //saída do lcd
				 output reg LED_G,	//porta aberta - led verde
	             output reg LED_R,	//porta fechada - led vermelho
	             output reg[6:0]HEX0,	//print andar selecionado
	             output reg[6:0]HEX1
				 input [8:0]SW, 		//andar selecionado
				 input KEY0,         //botão para chamar o elevador
				 input CLOCK_50,		
				 );
	wire DLY_RST;
	reg rs = 0;
	reg [31:0] aux;
	reg [31:0] CLOCK;
	reg [31:0] aux2;
	reg [31:0] CLOCK2;
	reg [60:0] aux3;
	reg [60:0] CLOCK3;
	
	
	// turn LCD ON
	assign    LCD_ON      =    1'b1;
	assign    LCD_BLON    =    1'b1;
	
	//reg verifica_reset = 0;
	// integer movimento; // 0 - parado, 1 - subindo, 2 - descendo 
	integer s; //andar solicitado
	integer aux_s; //andar atual
	reg [1:0] estado_atual;
	parameter parado = 0, subindo = 1, descendo = 2;// inativo = 3;
	// parado, subindo ou descendo 		
	
	always @(posedge CLOCK_50)begin //Por conta do clock_50 ser muito rápido, fez-se necessário aumentar o tempo para mudança de estado
		if(aux == 0)begin //O aux irá para um valor muito alto toda vez que chegar a 0
			aux  <= 24999999;
			CLOCK <= ~CLOCK;
		end else begin
			aux <= aux - 1; //Começando por 24999999, o valor do aux será diminuído para que leve mais tempo para mudança de estado
		end
	end
	
	always @(posedge CLOCK_50)begin // Similar ao exemplo de cima, porém, leva o dobro de tempo
		if(aux2 == 0)begin
			aux2  <= 49999999;
			CLOCK2 <= ~CLOCK2;
		end else begin
			aux2 <= aux2 - 1;
		end
	end	
	
	
	always @( negedge KEY0 ) begin //KEY0 é o botão do FPGA, será apertado quando o usuário quiser subir ou descer, parte COMBINACIONAL
		case (SW) 	//SW é a chave que o usuário ligou
						9'b000000001: begin
							HEX0 = 7'b1000000; //se o andar selecionado pela chave for 0
							s = 0;
						end	
						
						9'b000000010: begin
							HEX0 = 7'b1111001; //se o andar selecionado pela chave for 1
							s = 1;
						end
						
						9'b000000100: begin
							HEX0 = 7'b0100100; //se o andar selecionado pela chave for 2
							s = 2;
						end
						
						9'b000001000: begin
							HEX0 = 7'b0110000; //se o andar selecionado pela chave for 3
							s = 3;
						end	
						
						9'b000010000: begin
							HEX0 = 7'b0011001; //se o andar selecionado pela chave for 4
							s = 4;
						end
						
						9'b000100000: begin
							HEX0 = 7'b0010010; //se o andar selecionado pela chave for 5
							s = 5;
						end
						
						9'b001000000: begin
							HEX0 = 7'b0000010; //se o andar selecionado pela chave for 6
							s = 6;
						end
						
						9'b010000000: begin 
							HEX0 = 7'b1111000; //se o andar selecionado pela chave for 7
							s = 7;
						end
						
						9'b100000000: begin 
							HEX0 = 7'b0000000; //se o andar selecionado pela chave for 8                                                                                                                                                                                                              1; //se o andar selecionado for 8
							s = 8;
						end
						
						default: begin 
							HEX0 = 7'b1110111;  //default: _ , nenhuma andar solicitado
						end 
			endcase
	end
	

	always begin // O aux_s vai representar o estado atual do elevador (andar atual), e seu valor será representado no segundo display de sete segmentos da direita para a esquerda, parte COMBINACIONAL 	
		case (aux_s)
			0: begin
				HEX1 = 7'b1000000; //Se o estado atual for 0, andar atual = 0
			end
			
			1: begin 
				HEX1 = 7'b1111001; //Se o estado atual for 1, andar atual = 1
			end
			
			2: begin 
				HEX1 = 7'b0100100; //Se o estado atual for 2, andar atual = 2
			end
			
			3: begin 
				HEX1 = 7'b0110000; //Se o estado atual for 3, andar atual = 3
			end
			
			4: begin 
				HEX1 = 7'b0011001; //Se o estado atual for 4, andar atual = 4
			end
			
			5: begin 
				HEX1 = 7'b0010010; //Se o estado atual for 5, andar atual = 5
			end
			
			6: begin 
				HEX1 = 7'b0000010; //Se o estado atual for 6, andar atual = 6
			end
			
			7: begin 
				HEX1 = 7'b1111000; //Se o estado atual for 7, andar atual = 7
			end
			
			8: begin 
				HEX1 = 7'b0000000; //Se o estado atual for 8, andar atual = 8
			end
		endcase
	end
	
	always @( CLOCK ) begin // Representação dos LED's 
		if ( estado_atual == parado ) begin // Quando o elevador estiver parado o LED aceso será o verde
			LED_G = 1;
			LED_R = 0;
		end 
		else begin // Quando o elevador estiver se movendo o LED aceso será o vermelho
			LED_G = 0;
			LED_R = 1;
		end
		
	end
	
	
	always @( posedge CLOCK2 ) begin // O atributo reset representará um update no estado, e toda vez que for 1, significa que o LCD mudou, parte SEQUENCIAL 
		rs = 0;
		case (estado_atual)
			
			parado: begin
			
				if (s > aux_s ) begin 
					estado_atual = subindo; // Caso o s que é o andar para onde o elevador quer chegar for maior do que o aux_s (estado atual), ele estará subindo
					rs = 1;		
				end else if (s < aux_s) begin
					estado_atual = descendo; // Caso o s que é o andar para onde o elevador quer chegar for menor do que o aux_s (estado atual), ele estará descendo
					rs = 1;
				end
			end
			
			subindo: begin
				aux_s = aux_s + 1; // Como irá subir, o estado atual será incrementado
				if (s == aux_s) begin
					estado_atual = parado; // Como está igual ao andar que o elevador deseja chegar, o estado é parado, e mudará o reset porque o estado será atualizado
					rs = 1;
				end
			end
			descendo: begin 
				aux_s = aux_s - 1; // Como irá descer, o estado atual será decrementado
				if (s == aux_s ) begin
					estado_atual = parado; // idem a linha 179
					rs = 1;
				end
			end
			endcase
			
	end		
	
	
	Reset_Delay r0(    .iCLK(CLOCK_50),.oRESET(DLY_RST));

	
	LCD_TEST u1( // Chamada das funções do LCD_TEST, que irá printar no LCD
		// Host Side
		.iCLK(CLOCK_50),
		.iRST_N(DLY_RST),
		// LCD Side
		.LCD_DATA(LCD_DATA),
		.LCD_RW(LCD_RW),
		.LCD_EN(LCD_EN),
		.LCD_RS(LCD_RS),
		.estado_atual(estado_atual),
		.Reset(rs)
	);
		
	
endmodule
		
