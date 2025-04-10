import mediaQuery from '@ohos.mediaquery'
import { debuglog } from '../utils/log'

export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl'

export interface Breakpoint {
  name: BreakpointType
  size: number
  mediaQueryListener?: mediaQuery.MediaQueryListener
}

export class BreakpointSystem {
  private static instance: BreakpointSystem
  private readonly breakpoints: Breakpoint[] = [
    { name: 'xs', size: 0 },
    { name: 'sm', size: 320 },
    { name: 'md', size: 600 },
    { name: 'lg', size: 840 }
  ]
  private states: Set<BreakpointState<Object>>
  private listenerEd: boolean = false

  private constructor() {
    this.states = new Set()
  }

  public static getInstance(): BreakpointSystem {
    if (!BreakpointSystem.instance) {
      BreakpointSystem.instance = new BreakpointSystem();
    }
    return BreakpointSystem.instance
  }

  public attach(state: BreakpointState<Object>): void {
    this.states.add(state)
    this.start()
  }

  public detach(state: BreakpointState<Object>): void {
    this.states.delete(state)
  }

  public start() {
    this.breakpoints.forEach((breakpoint: Breakpoint, index) => {
      let condition: string
      if (index === this.breakpoints.length - 1) {
        condition = `(${breakpoint.size}vp<=width)`
      } else {
        condition = `(${breakpoint.size}vp<=width<${this.breakpoints[index + 1].size}vp)`
      }

      breakpoint.mediaQueryListener = mediaQuery.matchMediaSync(condition)
      if (breakpoint.mediaQueryListener.matches) {
        this.updateAllState(breakpoint.name)
      }

      if (!this.listenerEd) {
        breakpoint.mediaQueryListener.on('change', (mediaQueryResult) => {
          console.log('mediaQueryResult',mediaQueryResult)
          if (mediaQueryResult.matches) {
            this.updateAllState(breakpoint.name)
          }
        })
      }
    })

    this.listenerEd = true
  }

  private updateAllState(type: BreakpointType): void {
    this.states.forEach(state => state.update(type))
  }

  public stop() {
    this.breakpoints.forEach((breakpoint: Breakpoint, index) => {
      if (breakpoint.mediaQueryListener) {
        breakpoint.mediaQueryListener.off('change')
      }
    })
    this.states.clear()
    this.listenerEd = false
  }
}

export interface BreakpointOptions<T> {
  xs?: T
  sm?: T
  md?: T
  lg?: T
  xl?: T
  xxl?: T
}

@ObservedV2
export class BreakpointState<T extends Object> {
  @Trace public value: T | undefined = undefined;
  @Trace private options: BreakpointOptions<T>

  constructor(options: BreakpointOptions<T>) {
    this.options = options
  }

  static of<T extends Object>(options: BreakpointOptions<T>): BreakpointState<T> {
    return new BreakpointState(options)
  }

  public update(type: BreakpointType): void {
    // debuglog('type', type)
    if (type === 'xs') {
      this.value = this.options.xs
    } else if (type === 'sm') {
      this.value = this.options.sm
    } else if (type === 'md') {
      this.value = this.options.md
    } else if (type === 'lg') {
      this.value = this.options.lg
    } else if (type === 'xl') {
      this.value = this.options.xl
    } else if (type === 'xxl') {
      this.value = this.options.xxl
    } else {
      this.value = undefined
    }
  }
}