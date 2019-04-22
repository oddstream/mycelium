// @ts-check
'use strict';

let Loop6 = (function() {

window.LOOP6_VERSION = '0.4.20.0';  // for bake

let DEBUGGING = false;

const Q = 80;

const W = 2 * Q;
const W75 = Math.floor(W*0.75);
const W50 = Math.floor(W*0.5);
const W25 = Math.floor(W*0.25);

const H = Math.floor(Math.sqrt(3) * Q);
const H75 = Math.floor(H*0.75);
const H50 = Math.floor(H*0.5);
const H25 = Math.floor(H*0.25);

const Q33 = Math.floor(Q/3.333);    const strQ33 = Q33.toString();
const Q10 = Math.floor(Q/10);       const strQ10 = Q10.toString();

const innerRadius = Q * 0.86602529158357;  // cosine of 30 degrees, hypotenuse

const SVG_NAMESPACE = 'http://www.w3.org/2000/svg';

const BACKGROUND_COLOR = 'Black';
const COMPLETED_COLOR = 'White';
const OUTLINE_COLOR = 'DarkGrey';

const NORTH     = 0b000001;
const NORTHEAST = 0b000010;
const SOUTHEAST = 0b000100;
const SOUTH     = 0b001000;
const SOUTHWEST = 0b010000;
const NORTHWEST = 0b100000;

// too low, produces too many double circle entities
// too high, grid is too crowded
const PLACE_COIN_CHANCE = 0.4;

const isOdd = (x) => { return (x&1)==1; };

// distance from centre to midpoint of diagonal edge = Math.sqrt(3)/2*Q50
const cellData = [
    { bit: NORTH,       oppBit: SOUTH,     link: 'n',      c2eX: 0,        c2eY: -H50,  },
    { bit: NORTHEAST,   oppBit: SOUTHWEST, link: 'ne',     c2eX: W*3/8,    c2eY: -H/4,  },
    { bit: SOUTHEAST,   oppBit: NORTHWEST, link: 'se',     c2eX: W*3/8,    c2eY: H/4,   },
    { bit: SOUTH,       oppBit: NORTH,     link: 's',      c2eX: 0,        c2eY: H50,   },
    { bit: SOUTHWEST,   oppBit: NORTHEAST, link: 'sw',     c2eX: -W*3/8,   c2eY: H/4,   },
    { bit: NORTHWEST,   oppBit: SOUTHEAST, link: 'nw',     c2eX: -W*3/8,   c2eY: -H/4,  }
];

const gameState = new GameState(6);

class Cell
{
    constructor(svg, x, y, centre)
    {
        this.svg = svg;
        this.x = x;
        this.y = y;
        this.centre = centre;
        this.n  = this.ne = this.se = this.s = this.sw = this.nw = null;
        this.coins = this.originalCoins = 0;
        this.g = null;
        this.color = null;
    }

    /**
     * Fifth attempt at animating the rotation of a cell when the user clicks on it
     * @returns {Promise} which completes when the animation is finished
     */
    rotate5()
    {
        const thisCell = this;

        return new Promise(function(resolve/*, reject*/)
        {
            let angle = 10;

            const spinSVG = () => {
                thisCell.g.setAttributeNS(null, 'transform', `rotate(${angle} ${thisCell.centre.x},${thisCell.centre.y})`);
                angle += 10;
                if ( angle < 60 )
                    window.requestAnimationFrame(spinSVG);
                else
                    resolve();
            };
            window.requestAnimationFrame(spinSVG);
        });
    }

    shiftBits(num = 1)
    {
        while ( num-- )
        {
            if ( this.coins & 0b100000 )
                this.coins = ((this.coins << 1) & 0b111111) | 0b000001;
            else
                this.coins = (this.coins << 1) & 0b111111;
        }
    }

    unshiftBits(num = 1)
    {
        while ( num-- )
        {
            if ( this.coins & 0b000001 )
                this.coins = (this.coins >> 1) | 0b100000;
            else
                this.coins = this.coins >> 1;
        }
    }

    mirrorCoins()
    {
      let c = 0;
      if ( this.coins & NORTH )
        c = c | NORTH;
      if ( this.coins & SOUTH )
        c = c | SOUTH;
      if ( this.coins & NORTHEAST )
        c = c | NORTHWEST;
      if ( this.coins & SOUTHEAST )
        c = c | SOUTHWEST;
      if ( this.coins & SOUTHWEST )
        c = c | SOUTHEAST;
      if ( this.coins & NORTHWEST )
        c = c | NORTHEAST;
      this.coins = c;
    }

    isComplete()
    {
        for ( let chkLink of cellData.filter(chk => this.coins & chk.bit) )
        {
            if ( this[chkLink.link] === null )
                return false;
            if ( !(this[chkLink.link].coins & chkLink.oppBit) )
                return false;
        }
        return true;
    }

    placeCoin()
    {
        if ( this.s )
        {
            if ( Math.random() < PLACE_COIN_CHANCE )
            {
                this.coins = this.coins | SOUTH;
                this.s.coins = this.s.coins | NORTH;
            }
        }
        if ( this.ne )
        {
            if ( Math.random() < PLACE_COIN_CHANCE )
            {
                this.coins = this.coins | NORTHEAST;
                this.ne.coins = this.ne.coins | SOUTHWEST;
            }
        }
        if ( this.se )
        {
            if ( Math.random() < PLACE_COIN_CHANCE )
            {
                this.coins = this.coins | SOUTHEAST;
                this.se.coins = this.se.coins | NORTHWEST;
            }
        }
    }

    jumbleCoin()
    {
      let n = Math.floor(Math.random() * 5)
      console.assert(n>=0 && n<6)
      this.shiftBits(n);
      return;

        if ( DEBUGGING )
        {
            if ( Math.random() > 0.95 )
                this.unshiftBits();
        }
        else
        {
            if ( Math.random() < 0.5 ) //gameState.jumbleCoinChance )
            {
                if ( Math.random() > 0.75 )
                    this.shiftBits();
                else
                    this.unshiftBits();
            }
        }
    }

    colorComplete()
    {
      if ( this.g )
      {
        let eleList = this.g.querySelectorAll('line, circle, path');
        eleList.forEach( ele => ele.setAttributeNS(null, 'stroke', COMPLETED_COLOR) );
      }
    }

    setGraphic()
    {
        // document > svg > g|path > path|circle|line
        if ( this.g )
        {
            this.g.removeAttributeNS(null, 'transform');
            while ( this.g.firstChild )
                this.g.removeChild(this.g.firstChild);
        }
        else
        {
            this.g = document.createElementNS(SVG_NAMESPACE, 'g');
            this.svg.appendChild(this.g);
        }

        if ( 0 == this.coins )
            return;

        const bitCount = Util.hammingWeight(this.coins);
        if ( 1 == bitCount )
        {
            const eleLine = document.createElementNS(SVG_NAMESPACE, 'line');
            const b2p = cellData.find( ele => this.coins == ele.bit );
            eleLine.setAttributeNS(null, 'x1', this.centre.x);
            eleLine.setAttributeNS(null, 'y1', this.centre.y);
            eleLine.setAttributeNS(null, 'x2', this.centre.x + b2p.c2eX);
            eleLine.setAttributeNS(null, 'y2', this.centre.y + b2p.c2eY);
            eleLine.setAttributeNS(null, 'stroke', this.color);
            this.g.appendChild(eleLine);

            const eleSvgCircle = document.createElementNS(SVG_NAMESPACE, 'circle');
            eleSvgCircle.setAttributeNS(null, 'cx', this.centre.x.toString());
            eleSvgCircle.setAttributeNS(null, 'cy', this.centre.y.toString());
            eleSvgCircle.setAttributeNS(null, 'r', strQ33);
            eleSvgCircle.setAttributeNS(null, 'stroke', this.color);
            eleSvgCircle.setAttributeNS(null, 'fill', BACKGROUND_COLOR);
            this.g.appendChild(eleSvgCircle);
        }
        else
        {
            /*
                The initial M directive moves the pen to the first point (100,100).
                Two co-ordinates follow the ‘Q’; the single control point (50,50) and the final point we’re drawing to (0,0).
                It draws perfectly good straight lines, too, so no need for separate 'line' element.
            */
            let path = undefined;
            let cdFirst = undefined;
            for ( let cd of cellData )
            {
                if ( this.coins & cd.bit )
                {
                    if ( !path )
                    {
                        cdFirst = cd;
                        path = `M${this.centre.x + cd.c2eX},${this.centre.y + cd.c2eY}`;
                    }
                    else
                    {
                        path = path.concat(` Q${this.centre.x},${this.centre.y} ${this.centre.x + cd.c2eX},${this.centre.y + cd.c2eY}`);
                    }
                }
            }
            if ( bitCount > 2 )  // close the path for better aesthetics
                path = path.concat(` Q${this.centre.x},${this.centre.y} ${this.centre.x + cdFirst.c2eX},${this.centre.y + cdFirst.c2eY}`);

            const ele = document.createElementNS(SVG_NAMESPACE, 'path');
            ele.setAttributeNS(null, 'd', path);
            ele.setAttributeNS(null, 'stroke', this.color);
            this.g.appendChild(ele);
        }
    }
}

class Honeycomb
{
    constructor(numX=8, numY=5)
    {
        this.numX = numX;
        this.numY = numY;
        this.cells = new Array();  // array of cells

        document.title = `Loop 6 Level ${gameState.level}`;

        const eleWrapper = document.createElement('div');
        eleWrapper.style.backgroundColor = BACKGROUND_COLOR;

        // create an SVG element
        this.svg = document.createElementNS(SVG_NAMESPACE, 'svg');
        this.svg.setAttributeNS(null, 'width', ((numX+1)*W).toString());
        this.svg.setAttributeNS(null, 'height', ((numY+1)*H).toString());
        this.svg.setAttributeNS(null, 'stroke-width', strQ10);
        this.svg.setAttributeNS(null, 'fill', 'none');

        for ( let y=0; y<numY; y++ )
        {
            for ( let x=0; x<numX; x++)
            {
              // https://www.redblobgames.com/grids/hexagons/
              // "odd-q" vertical layout shoves odd columns down (by half height)
                let centre = {x:W+ x*W75, y:H+ y*H}
                if ( isOdd(x) ) {
                  centre.y += H50;
                }

                const c = new Cell(this.svg, x, y, centre);
                this.cells.push(c);

                if ( DEBUGGING )
                {
                    const eleSvgPath = document.createElementNS(SVG_NAMESPACE, 'path');
                    eleSvgPath.setAttributeNS(null, 'd', this.createOutlinePath(centre));
                    eleSvgPath.setAttributeNS(null, 'stroke-width', '1');
                    eleSvgPath.setAttributeNS(null, 'stroke', OUTLINE_COLOR);
                    this.svg.appendChild(eleSvgPath);

                    const eleSvgText = document.createElementNS(SVG_NAMESPACE, 'text');
                    eleSvgText.setAttributeNS(null, 'x', centre.x.toString());
                    eleSvgText.setAttributeNS(null, 'y', centre.y.toString());
                    eleSvgText.setAttributeNS(null, 'stroke-width', '1');
                    eleSvgText.innerHTML = `${x},${y}`;
                    this.svg.appendChild(eleSvgText);
                }
            }
        }

        this.svg.addEventListener(/*'click'*/'pointerup', this);     // <g> and <path> &c don't accept listeners

        eleWrapper.appendChild(this.svg);
        document.body.appendChild(eleWrapper);

        document.body.onkeydown = this.handleEventKeyDown.bind(this);
    }

    createOutlinePath(c)
    {
        return `M${c.x-W25} ${c.y-H50} L${c.x+W25} ${c.y-H50} L${c.x+W50} ${c.y} L${c.x+W25} ${c.y+H50} L${c.x-W25} ${c.y+H50} L${c.x-W50} ${c.y} Z`;
    }

    linkCells()
    {
        this.cells.forEach(c => {
            let t = undefined;  // the target we are looking for
            t = this.cells.find( d => (c.centre.x == d.centre.x) && (c.centre.y == d.centre.y-H) );
            if ( t )
            {
                c.s = t;
                t.n = c;
            }
            t = this.cells.find( d => (c.centre.x == d.centre.x-W75) && (c.centre.y == d.centre.y+H50) );
            if ( t )
            {
                c.ne = t;
                t.sw = c;
            }
            t = this.cells.find( d => (c.centre.x == d.centre.x-W75) && (c.centre.y == d.centre.y-H50) );
            if ( t )
            {
                c.se = t;
                t.nw = c;
            }
        });
        return this;
    }

    placeCoins(sym=false)
    {
        for ( const c of this.cells )
        {
          c.placeCoin();
        }
        if ( sym )
        {
          let halfX = Math.floor(this.numX / 2);
          console.log(halfX);
          for ( let y=0; y<this.numY; y++ )
          {
            for ( let xSrc=0; xSrc<halfX; xSrc++ )
            {
              let xDst = this.numX - 1 - xSrc;
              let cSrc = this.cells.find( d => (d.x == xSrc) && (d.y == y) );
              console.assert(cSrc);
              let cDst = this.cells.find( d => (d.x == xDst) && (d.y == y) );
              console.assert(cDst);
              cDst.coins = cSrc.coins;
              cDst.mirrorCoins();
            }
            // now fudge the middle column, assumes odd number of columns
            let cHalf = this.cells.find( d => (d.x == halfX) && (d.y == y) );
            cHalf.coins = 0;
            let cLeft = this.cells.find( d => (d.x = halfX - 1) && (d.y == y) );
            cLeft.coins &= ~(NORTHEAST | SOUTHEAST); cLeft.coins &= 0b111111;
            let cRight = this.cells.find( d => (d.x = halfX + 1) && (d.y == y) );
            cRight.coins &= ~(NORTHWEST | SOUTHWEST); cRight.coins &= 0b111111;
          }
        }
        for ( const c of this.cells )
        {
          c.originalCoins = c.coins;
        }
        return this;
    }

    colorCoins()
    {
      let COLORS = ['DarkGreen','ForestGreen','MediumSeaGreen','DarkSeaGreen','OliveDrab','Olive','DarkOliveGreen'];

      /**
       * 
       * @param {Cell} c 
       * @param {Number} n 
       */
      function color(c, n)
      {
        console.assert(c!==null);
        console.assert(c!==undefined);
        console.assert(c.color===null);
        c.color = COLORS[n];
        for ( let chkLink of cellData.filter(chk => c.coins & chk.bit))
        {
          let cn = c[chkLink.link];
          if ( cn !== null && cn.coins && cn.color === null )
            color(cn, n);
        }
      }

      for ( let n = 0, c = this.cells.find( d => (d.coins && d.color === null) ); c !== undefined; c = this.cells.find( d => (d.coins && d.color === null) ) )
      {
        color(c, n++);
      }
      return this;
    }

    jumbleCoins()
    {
        while ( this.isComplete() )
            for ( const c of this.cells )
                c.jumbleCoin();
        return this;
    }

    setGraphics()
    {
        this.cells.forEach(c => {
            c.setGraphic();
        });
        return this;
    }

    isComplete()
    {
        for ( const c of this.cells )
            if ( !c.isComplete() )
                return false;
        return true;
    }

    colorAll()
    {
      for ( const c of this.cells )
        c.colorComplete();
    }

    handleEvent(event)
    {
        if ( this.isComplete() )
        {
            window.location.reload(false);
            return;
        }

        for ( const c of this.cells )
            if ( Util.pointInCircle(event.offsetX, event.offsetY, c.centre.x, c.centre.y, innerRadius) )
            {
                c.rotate5()
                .then( () => {
                    c.shiftBits();
                    c.setGraphic();
                    if ( this.isComplete() )
                    {
                        // this.svg.setAttributeNS(null, 'stroke', COMPLETED_COLOR);
                        this.colorAll();
                        gameState.gridSolved();
                    }
                });
                break;
            }
    }

    handleEventKeyDown(event)
    {   // 'event' is a KeyboardEvent object, event.type == "keydown"
        if ( event.code == 'KeyB' )
        {
            for ( const c of this.cells )
                c.coins = c.originalCoins = 0;
            this.setGraphics();
        }

        if ( event.code == 'KeyJ' )
        {
            for ( const c of this.cells )
                c.jumbleCoin();
            this.setGraphics();
        }

        if ( event.code == 'KeyU')
        {
            for ( const c of this.cells )
                c.coins = c.originalCoins;
            this.setGraphics();
        }
    }
}

function main()
{
    const urlParams = Util.getCommandLine();

    DEBUGGING = urlParams.debug ? urlParams.debug : DEBUGGING;
    let numX = urlParams.x ? urlParams.x : Math.max(Math.floor(window.innerWidth / W), 3);
    numX += 1;
    let numY = urlParams.y ? urlParams.y : Math.max(Math.floor(window.innerHeight / H), 3);
    numY -= 1;
    console.log(numX, numY);
    const h = new Honeycomb(numX, numY);
    h.linkCells().placeCoins().colorCoins().jumbleCoins().setGraphics();
}

main();

})();
