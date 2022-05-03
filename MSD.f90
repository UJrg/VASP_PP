PROGRAM MSD
! Purpose:
!   This program reads XDATCAR file generated by VASP and calculates mean squared
!   displacement (MSD) for each type of element in the simulation cell.
  
	IMPLICIT NONE
    INTEGER n_element, start_t, end_t, skip_t
    INTEGER i, j, t, n, m, q, p, k, l, index, atom
    CHARACTER*2, DIMENSION(:), ALLOCATABLE :: names
    INTEGER, DIMENSION(:), ALLOCATABLE :: n_atoms
    REAL*8, dimension(3,3) :: bravais
    REAL*8, DIMENSION(:,:,:), ALLOCATABLE :: conf
    REAL*8 len1, len2, len3, volume, s


! Prompt the user for system specific information

    WRITE(*,*)'How many different elements do you have in your system?'
    WRITE(*,*) n_element
    WRITE(*,*)'How many MD steps do you wish me to throw away?'
    WRITE(*,*) start_t
    WRITE(*,*)'Enter the ending MD step'
    WRITE(*,*) end_t
   
   
    ALLOCATE(names(n_element))
    ALLOCATE(n_atoms(n_element))
    
	
    OPEN(501, FILE = 'XDATCAR')
    READ(501, *)
    READ(501, *)
    READ(501, *) br(1,1), br(1,2), br(1,3)
    READ(501, *) br(2,1), br(2,2), br(2,3)
    READ(501, *) br(3,1), br(3,2), br(3,3)
    READ(501, *) names
    READ(501, *) n_atoms


    volume = br(1,1) * br(2,2) * br(3,3) - br(1,1) * br(2,3) * br(3,2) + &
             br(1,2) * br(2,3) * br(3,1) - br(1,2) * br(2,1) * br(3,3) + &
             br(1,3) * br(2,1) * br(3,2) - br(1,3) * br(2,2) * br(3,1)
 
    len1 = SQRT(br(1,1) * br(1,1) + br(1,2) * br(1,2) + br(1,3) * br(1,3))
    len2 = SQRT(br(2,1) * br(2,1) + br(2,2) * br(2,2) + br(2,3) * br(2,3))
    len3 = SQRT(br(3,1) * br(3,1) + br(3,2) * br(3,2) + br(3,3) * br(3,3))
   

    ALLOCATE(conf(end_t - start_t, SUM(n_atoms), 3))
   
   
    DO t = 1, end_t
        READ(501, *)
		IF (t > start_t) THEN
			DO p = 1, SUM(n_atoms)
				READ(501, *) conf(t - start_t, p, 1), conf(t - start_t, p, 2), conf(t - start_t, p, 3)
			END DO
		ELSE
			DO p = 1, SUM(n_atoms)
				READ(501, *)
			END DO
		END IF
    END DO
	
	DO t = 2, end_t - start_t
		DO n = 1, SUM(n_atoms)
			DO index = 1, 3
				IF (ANINT(conf(t, n, index)-conf(t-1, n, index)) > 0) THEN
					PRINT*, n
					conf(t, n, index) = conf(t, n, index) - ANINT(conf(t, n, index) - conf(t - 1, n, index))
				END IF
				IF (ANINT(conf(t, n, index)-conf(t - 1, n, index)) < 0) THEN
					PRINT*, n
					conf(t, n, index) = conf(t, n, index) - ANINT(conf(t, n, index) - conf(t - 1, n, index))
				END IF
			END DO
		END DO
	END DO
	

! Open separate text file for each type of element and write MD step with corresponding MSD

	i = 1
	DO n = 1, n_element
		OPEN(1, FILE = names(n), STATUS = 'new')
			DO t=2, end_t-start_t
				s = 0
				DO atom = i, i + n_atoms(n) - 1
					jami = jami + (br(1, 1) * conf(t, atom, 1) - br(1, 1) * conf(1, atom, 1)) ** 2 + &
					(br(2, 2) * conf(t, atom, 2) - br(2, 2) * conf(1, atom, 2)) ** 2 + &
					(br(3, 3) * conf(t, atom, 3) - br(3, 3) * conf(1, atom, 3)) ** 2 
				END DO
				WRITE(1,*) t, s / n_atoms(n)
			END DO
			i = i + n_atoms(n)
	END DO
			
END PROGRAM MSD
