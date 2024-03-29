--Electronica Digital 2º curso EITE/ULPGC
--Para usar únicamente en los Trabajos de asignatura
--Datapath del multiplicador

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  USE work.ALL;

ENTITY multiplier_datapath IS
	GENERIC(
		n : INTEGER:= 4;     -- Número de bits
        m : INTEGER:= 2);    -- log2 número de bits
	PORT(
		clock      : IN  STD_LOGIC;
        reset_n    : IN STD_LOGIC;
        enable     : IN STD_LOGIC;
        inicio     : IN STD_LOGIC;
		x_in, y_in : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        p_out      : OUT STD_LOGIC_VECTOR(2*n-1 DOWNTO 0);
        done       : OUT STD_LOGIC
	);
END multiplier_datapath;

ARCHITECTURE trabajo OF multiplier_datapath IS
	COMPONENT registro_enable IS
		GENERIC(n : INTEGER := 8);
		PORT(
			clk		:	IN STD_LOGIC;
			rstn	:	IN STD_LOGIC;
			enable	:	IN STD_LOGIC;
			entrada	:	IN UNSIGNED (n-1 DOWNTO 0);
			salida	:	OUT UNSIGNED (n-1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT contador_k IS
		GENERIC(
			k : INTEGER := 4;
			m : INTEGER:= 2);
		PORT(
			clock		: IN STD_LOGIC;
			reset_n	: IN STD_LOGIC;
			enable		: IN STD_LOGIC;
			fin_cuenta: OUT STD_LOGIC
		);
	END COMPONENT;
	
	-- SEÑALES
	SIGNAL X: UNSIGNED (3 DOWNTO 0);
	SIGNAL ph: UNSIGNED (3 DOWNTO 0);			-- Inicialmente se inicializa a 0 y después la parte alta de la salida
	SIGNAL pl: UNSIGNED (3 DOWNTO 0);			-- Inicialmente se inicializa con el valor de "y_in" y después la parte baja de la salida
	SIGNAL LSB: STD_LOGIC;
	SIGNAL salida_ALU: UNSIGNED (4 DOWNTO 0);	-- Almacena la salida de la ALU

	SIGNAL m1: UNSIGNED (3 DOWNTO 0);			-- Salida del primer multiplexor que almacenará la parte alta
	SIGNAL m2: UNSIGNED (3 DOWNTO 0);			-- Salida del segundo multiplexor que almacenará la parte baja
	SIGNAL union: UNSIGNED (7 DOWNTO 0);		-- Almacena la salida de ambos multiplexores
	SIGNAL p: UNSIGNED (7 DOWNTO 0);			-- Une parte alta y parte baja
    SIGNAL enable_registro : STD_LOGIC;			-- Se pondrá a 1 para que el contador empiece a contar en el momento preciso


	BEGIN
		ph <= (OTHERS => '0') WHEN inicio = '1' ELSE p(7 DOWNTO 4);
		pl <= UNSIGNED(y_in) WHEN inicio = '1' ELSE p(3 DOWNTO 0);
		LSB <= pl(0);
        enable_registro <= enable XOR inicio;

		--
		-- Registro que almacena 'x_in'
		--
		registro_x: registro_enable
			GENERIC MAP (n => 4)
			PORT MAP(
				clk => clock,
				rstn => reset_n,
				enable => inicio,
				entrada => UNSIGNED(x_in),
				salida => X
			);

		--
		-- ALU
		--
		salida_ALU <= '0' & ph WHEN LSB = '0' ELSE '0' & (ph + X);

		--
		-- MULTIPLEXORES
		--
		m1 <= (OTHERS => '0') WHEN inicio = '1' ELSE salida_ALU(4 DOWNTO 1);
		m2 <= UNSIGNED(y_in) WHEN inicio = '1' ELSE salida_ALU(0) & pl(3 DOWNTO 1);
		union <= m1 & m2;

		--
		-- Registro que almacena la salida de los multiplexores
		--
		registro_p: registro_enable
        	GENERIC MAP (n => 8)
			PORT MAP(
				clk => clock,
				rstn => reset_n,
				enable => enable,
				entrada => union,
				salida => p
			);

		--
		-- Asigno el valor de la salida
		--
		p_out <= STD_LOGIC_VECTOR(p);

		--
		-- Contador que controla los 4 pasos para multiplicar
		--
		contador: contador_k
			PORT MAP(
				clock => clock,
				reset_n => reset_n,
				enable => enable_registro,
				fin_cuenta => done
			);

END trabajo;
