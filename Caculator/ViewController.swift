//
//  ViewController.swift
//  Caculator
//
//  Created by Lan on 16/2/27.
//  Copyright © 2016年 SJTU. All rights reserved.
//

import UIKit

extension Character {
    func isDigit() -> Bool {
        return self >= "0" && self <= "9" ? true:false
    }
    func isOperator() -> Bool {
        switch self {
            case "+", "−", "×", "÷": return true
            default: return false
        }
    }
}

struct Stack<T> {
    var items = Array<T>()
    
    func top() -> T {
        // 如果没有.last则会crash
        return items.last!
    }
    mutating func push(item: T) {
        items.append(item) // 加在数组的后面，每次top也是取的最后一个元素，新push的元素就是top
    }
    
    mutating func pop() -> T {
        return items.removeLast()
    }
    
    func count() -> Int {
        return items.count
    }
    func isEmpty() -> Bool {
        return count() == 0
    }
}

enum Operator: String {
    case Add = "+"
    case Subtract = "−"
    case Multiply = "×"
    case Divide = "÷"
    
    // 每个操作符有自己的优先级
    var priority: Int {
        switch self {
            case Add:
                return 0
            case Subtract:
                return 0
            case Multiply:
                return 1
            case Divide:
                return 1
        }
    }
}

class ViewController: UIViewController {
    // define a property, its name is display, to show the result of caculator
    @IBOutlet weak var display: UILabel!
    // its type is UILable
    
    var operandStack = Stack<Operator>()
    var numberStack = Stack<Double>()
    var userIsInMiddleOfTyping: Bool = false
    var currentNum = ""
    var expressionIsInputting: Bool = false
    
    
    @IBAction func appendExpression(sender: UIButton) {
        let cur = sender.currentTitle!
        if expressionIsInputting {
            display.text = display.text! + cur
        }
        else{
            display.text = cur
            expressionIsInputting = true
        }
    }
    
    
    var expr: String {
        // 这个变量是显示在最上面的表达式
        get {
            return display.text!
        }
        set{
            display.text = expr
        }
    }
    
    var displayValue: Double { // 定义computed variable时Double后面没有 =
        get {
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            display.text = "\(newValue)"
        }
    }
    
    // [DONE]TODO : append后面的这个参数double的提取是可以用一个computed variable表示的，叫displayValue。
    // 即可以取当前显示的值的字符串然后转成double存储，也能将需要显示的数字display到屏幕
    
    @IBAction func caculate() {
        // 这个函数先取出计算变量的值
        expressionIsInputting = false
        // 现在改成：当用户输入完整的表达式，再整个取出这个表达式字符串，再从头开始处理这个字符串
        let exprStr = expr + "!"
//        print(exprStr)
        for i in exprStr.characters {
            if i.isDigit() {
                numberProcess(i)
            }
            else if i.isOperator() {
                addOpe(i)
            }
            else if i == "!" {
//                lastNum()
                addOpe("!")
            }
        }
        while !operandStack.isEmpty() {
            // 只要还有数字
//            print("numbers: \(numberStack). operator: \(operandStack)")
            let res = operateTwoNumbers()
            numberStack.push(res)
        }
        // 全部运算结束后，栈中只剩下最后一个值，就是结果
        displayValue = numberStack.pop()
    }
    
    func operateTwoNumbers() -> Double {
        let ope = operandStack.pop()
        let num2 = numberStack.pop()
        let num1 = numberStack.pop()
        
        switch ope {
        case .Add: return num1 + num2
        case .Subtract: return num1 - num2
        case .Multiply: return num1 * num2
        case .Divide: return num1 / num2
        }
    }

    func numberProcess(curChar: Character) {
        if userIsInMiddleOfTyping {
            currentNum += String(curChar)
        }
        else{
            // 说明是新的一个数字
            currentNum = String(curChar)
            userIsInMiddleOfTyping = true
        }
    }
    
    func addOpe(curOpe: Character) {
        // 1.新来一个符号的时候，先把当前的数字push到stack中，
        // 2. 获取当前的操作符
        // 3. 如果当前的操作符的优先级比preOperation的优先级高，就不进行操作；如果比xxx优先级低，就进行相应的operation
        
        // 每个操作符都说明是数字的结束，因此要讲数字进行push到栈中
        // [DONE][TODO] 有的时候用户连续输入多个操作符，这个时候就要判断输入的前一个字符是什么，如果也是操作符那么就要将前一个操作符弹出。这项功能的实现就不能在输入过程中同时入栈出栈了，
        // eg. 27+56+ 遇到第二个+号会首先计算27+56 => 27+56* 但是后来+换成了*，就不应该先计算27+56 但是现在已经计算了
        // 因此实现这个功能需要等用户整个表达式输入完成之后再对字符串进行入栈操作
        userIsInMiddleOfTyping = false
        if !userIsInMiddleOfTyping {
            // 将currentNum push到stack中
            numberStack.push((currentNum as NSString).doubleValue) // 将字符串转成Double
            currentNum = "" // 将当前的数字记录清空
        }
        // 获取当前的operation
        var curOperator : Operator? = nil
        switch curOpe {
        case "+": curOperator = .Add
        case "−": curOperator = .Subtract
        case "×": curOperator = .Multiply
        case "÷": curOperator = .Divide
        default:  break // 当传过来的是"!"时，curOperator = nil
        }
        
//         如果curOperation为nil，说明到了这个表达式的结尾，之前已经把数字push进去了，因此这里什么都不需要做
        // 获取前一个operation
        if !operandStack.isEmpty() && curOperator != nil {
            let preOperation = operandStack.top()
            if preOperation.priority >= curOperator!.priority {
                // 如果前一个符号的优先级更高or相等的话，刚刚push进栈的数和stack中倒数第二个数进行运算
                //            operandStack.push(curOperator!)
                let result = operateTwoNumbers()
                numberStack.push(result)
//                print("number stack: \(numberStack). operand stack: \(operandStack). ")
            }
            // 不管怎么样当前的操作符都要进栈
            // operandStack.push(curOperator!)
        }
        if curOperator != nil {
            operandStack.push(curOperator!)
        }
    }
}
