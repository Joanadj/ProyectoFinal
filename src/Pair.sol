// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";

contract Pair {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint public reserve0;
    uint public reserve1;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    // Recibir las direcciones de los dos tokens
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // Crear "posición"
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    // Quemar "posición"
    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // Actualizar reserva con los valores que pasan
    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    // Hacer el cambio, añadir la cantidad de token que te interesa
    function swap(address _tokenIn, uint _amountIn) external returns (uint amountOut) {
        require(
            _tokenIn == address(tokenA) || _tokenIn == address(tokenB),
            "invalid token"
        );
        require(_amountIn > 0, "amount in = 0");

        // Obtener la información del token que tenemos de entrada
        bool istokenA = _tokenIn == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = istokenA
            ? (tokenA, tokenB, reserve0, reserve1)
            : (tokenB, tokenA, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // Calculo cantidad con 0.3% de fees
        uint amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        tokenOut.transfer(msg.sender, amountOut);

        // Actualizar reserva con los valores nuevos (liquidez añadida)
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    // Depositar / Añadir liquidez
    function addLiquidity(uint _amountA, uint _amountB) external returns (uint shares) {
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        // Formula del cambio
        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amountB == reserve1 * _amountA, "x / y != dx / dy");
        }

        if (totalSupply == 0) {
            shares = _sqrt(_amountA * _amountB);
        } else {
            shares = _min(
                (_amountA * totalSupply) / reserve0,
                (_amountB * totalSupply) / reserve1
            );
        }
        require(shares > 0, "shares = 0");

        // Crear posición
        _mint(msg.sender, shares);

        // Actualizar reserva
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    // Quitar liquidez de la Pair
    function removeLiquidity(
        uint _shares
    ) external returns (uint amountA, uint amountB) {

        uint balA = tokenA.balanceOf(address(this));
        uint balB = tokenB.balanceOf(address(this));

        // Calcular dinero de cada uno del dinero total
        amountA = (_shares * balA) / totalSupply;
        amountB = (_shares * balB) / totalSupply;
        
        require(amountA > 0 && amountB > 0, "amountA or amountB = 0");

        // Quemar posición y actualizar reserva
        _burn(msg.sender, _shares);
        _update(balA - amountA, balB - amountB);

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    // Raiz cuadrada optimizada
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Devuelve el mínimo entre dos numeros
    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
