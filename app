# Monitor market price changes every 30 seconds (can be changed according to market liquidity)
# For whose price goes down more than 1%，execute buy order;
# Sell it at a higher price once the buy order was completed, the sell price could be lower than 30s ago but higher than buy price + fees;
# Monitor those increased more than 8% in one day because these currencies are more liquid;
# Stop buying one currency if contineously executed buy order for 4 times, control the down turn risk;
# Warning: this model may still be risky, those who use this model, bear your risk by yourself.

import os
import ccxt
import requests
import time
import datetime
import copy
from typing import Dict, List, Any, Union

print('***********************************************************\n')
print('            Cryptocurrency Auto-trading System --V1.6     ')
print('                                          --xx Exchange   ')
print('\n***********************************************************')

usd_rate = 7 # usdcny exchange rate
count = 0  # loop_count
n_buy = 0  # total buy orders
n_sell = 0  # total sell orders
bid_money = 50 # order value
buy_signal = 0.99 
sell_signal = 1.005 
fee = 0.001
total_asset_0 = 0
total_asset_1 = 0
buy_open_orders = {}
sell_open_orders = {}
day_growth = {}
high_risk = {}
error_num = 0
decision_data = [{'temp': 0}, {}]
digit_0 = ['ANKR', 'BTT', 'CHZ', 'COCOS', 'DENT', 'DOCK', 'DOGE', 'ERD', 'FUN', 'HOT', 'IOST', 'KEY', 'MFT', 'NPXS',
           'STORM', 'TFUEL', 'VET', 'WIN']
digit_1 = ['ADA', 'BAT', 'CELR', 'COS', 'CVC', 'ENJ', 'ETC', 'FTM', 'GTO', 'HBAR', 'MATIC', 'MITH', 'NKN', 'ONE',
           'REN', 'RVN', 'THETA', 'TRX', 'XLM', 'XRP', 'ZIL']
digit_2 = ['BAND', 'BEAM', 'BNB', 'DUSK', 'EOS', 'FET', 'HC', 'ICX', 'IOTA', 'LINK', 'MTL', 'NANO', 'NULS', 'OMG',
           'ONG', 'ONT', 'PAX', 'PERL', 'TOMO', 'WAN', 'WAVES', 'XTZ', 'ZRX', 'KAVA']
digit_3 = ['ALGO', 'ATOM', 'NEO', 'QTUM', ]
digit_5 = ['BCHABC', 'DASH', 'ETH', 'LTC', 'XMR', 'ZEC']
digit_6 = ['BTC']
digit_7 = ['BUSD', 'TUSD', 'USDC', 'USDS']
all_symbol = digit_0 + digit_1 + digit_2 + digit_3 + digit_5 + digit_6

time_begin = time.time()  
temp = datetime.datetime.fromtimestamp(time_begin)
time_str = temp.strftime("%Y%m%d%H%M%S")
log_name = 'xx_Exchange_Traing_History_File--' + time_str + '.txt' 
f = open(log_name, 'a')


api_key = "type in your key"
api_secret = "type in your secret number"
jin_binance = ccxt.binance({"apiKey": api_key, "secret": api_secret})
print('\n Connected to the exchange successfully...\n\n', file=f)
print('\n Connected to the exchange successfully...\n\n')
f.close()

class MyBinance(object):

    def __init__(self):
        self.usd_asset = 0
        self.cny_asset = 0
        self.n_bid = 0
        self.n_ask = 0
        self.ask_price = 0
        self.ask_amount = 0
        self.sell_id = 0
        self.price_info = {}
        self.price_close = {}
        self.balance = {}
        self.balance_free = {}
        self.balance_used = {}
        self.balance_total = {}
        self.balance_result = []
        self.ticker_url = "https://api.binance.com/api/v3/ticker/price"
        
    #
    def get_all_price(self):
        daygrowth_url = 'https://api.binance.com/api/v3/ticker/24hr'
        resp_ticker = requests.get(self.ticker_url)
        resp_ticker_json = resp_ticker.json()
        for i in all_symbol:
            resp_daygrowth = requests.get(daygrowth_url + '?symbol=' + i + 'USDT')
            if float(resp_daygrowth.json()['priceChangePercent']) > 8:
                day_growth[i] = resp_daygrowth.json()['priceChangePercent']
            time.sleep(0.1)
        
        time_stamp = time.time()
        temp = datetime.datetime.fromtimestamp(time_stamp)
        str1 = temp.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        print('Price data timestamp:  %s' % str1, file=f)
        print('Price data timestamp:  %s' % str1)
       
        for i in resp_ticker_json:
            if i['symbol'][-4:] == 'USDT':
                self.price_info[i['symbol'][:-4]] = i
                self.price_close[i['symbol'][:-4]] = float(i['price'])
        price_close_dcp = copy.deepcopy(self.price_close)
        del decision_data[0]
        decision_data.append(price_close_dcp)
        return decision_data

   
    def get_balance(self):
        self.balance = jin_binance.fetch_balance()
      
        for i, j in self.balance['free'].items():
            if j > 0:
                self.balance_free[i] = j
        for i, j in self.balance['used'].items():
            if j > 0:
               self.balance_used[i] = j
        for i, j in self.balance['total'].items():
            if j > 0:
                self.balance_total[i] = j
        self.balance_result = [self.balance_free, self.balance_used, self.balance_total]
    
    @staticmethod
    def amount_adjust(symbol, amount):
        symbol = symbol
        amount = amount
        if symbol in digit_0 and amount > 1:
            amount = int(amount)
        elif symbol in digit_1 and amount > 0.1:
            amount = int(amount * 10) / 10
        elif symbol in digit_2 and amount > 0.01:
            amount = int(amount * 100) / 100
        elif symbol in digit_3 and amount > 0.001:
            amount = int(amount * 1000) / 1000
        elif symbol in digit_5 and amount > 0.00001:
            amount = int(amount * 100000) / 100000
        elif symbol == 'BTC':
            amount = int(amount * 1000000) / 1000000
        else:
            amount = 0
            print("Warning: %sNot enough balance or not in the list！" % symbol, file=f)
            print("Warning: %sNot enough balance or not in the list！" % symbol)
        return amount

        # 执行卖出订单
    def sell_order(self, symbol, ask_price, ask_amount):
        symbol = symbol
        ask_price = ask_price
        ask_amount = self.amount_adjust(symbol[:-5], ask_amount)
        if ask_price * ask_amount >= 10:
            sell_order = jin_binance.create_order(symbol=symbol, type='limit',
                                                  side='sell', amount=ask_amount, price=ask_price)
            sell_id = sell_order['id']
            print("Execution Result:%f dollars sell %f %s sell order id=%s submitted" % (ask_price, ask_amount, symbol, sell_id), file=f)
            print("Execution Result:%f dollars sell %f %s sell order id=%s submitted" % (ask_price, ask_amount, symbol, sell_id))
            time.sleep(0.1)

    def buy_order(self, symbol, bid_price, bid_amount):
        global n_buy
        error_num = 0
        symbol = symbol
        bid_price = bid_price
        bid_amount = bid_amount
        self.amount_adjust(symbol, bid_amount)    
        if 10 <= bid_price * bid_amount <= self.balance_free['USDT']:
            if symbol not in buy_open_orders or (symbol in buy_open_orders and len(buy_open_orders[i][0]) < 5):
                try:
                    symbol = symbol + '/USDT'
                    buy_order = jin_binance.create_order(symbol=symbol, type='limit', side='buy',
                                                         amount=bid_amount, price=bid_price)
                    buy_open_orders[symbol].append(buy_order['id'])
                    # print('buy_open_orders = {0}'.format(buy_open_orders))
                    print("Execution Result:%fdollars buy %f %s buy order id=%ssubmitted" % (bid_price, bid_amount, symbol,
                                                            buy_order['id']), file=f)
                    print("Execution Result:%fdollars buy %f %s buy order id=%ssubmitted" % (bid_price, bid_amount, symbol,
                                                            buy_order['id']))
                    time.sleep(0.1)
                    self.n_bid += 1
                    n_buy += 1

                except Exception as errorMsg:
                    error_num += 1
                    print('Error: %s' % errorMsg, file=f)
                    print('Error: %s' % errorMsg)
                    print('Too fast order submission, or check if banlance lower than %d. Program will continue。' % bid_money,
                          file=f)
                    print('Too fast order submission, or check if banlance lower than %d. Program will continue。' % bid_money)
                    if error_num == 10:
                        exit()
            else:
                print('Warning：Continuously buying but cannot sell, check if %sis collapsing,WATCH OUT！' % symbol, file=f)
                print('Warning：Continuously buying but cannot sell, check if %sis collapsing,WATCH OUT！' % symbol)
        else:
            print("Warning: Not enough balance to buy %s price at %s name:%s,buy order not submitted！"
                  % (str(bid_amount), str(bid_price), symbol), file=f)
            print("Warning: Not enough balance to buy %s price at %s name:%s,buy order not submitted！"
                  % (str(bid_amount), str(bid_price), symbol))

    # 根据数据分析是否进行下单操作
    def execute_order(self):
        global n_buy, n_sell, count, bid_money, buy_signal, sell_signal, fee
        # 程序初始运行，先把现有存量货币全部挂当前价格上浮2%的卖单
        if count == 0:
            for i, j in self.balance_free.items():
                if i != 'USDT' and i in all_symbol:
                    ask_price = 1.02 * decision_data[1][i]
                    ask_amount = j
                    i = i + '/USDT'
                    self.sell_order(i, ask_price, ask_amount)
            
            for i in all_symbol:
                i = i + '/USDT'
                buy_open_orders[i] = []
            for i in all_symbol:
                i = i + '/USDT'
                try:
                    open_orders = jin_binance.fetch_open_orders(symbol=i)
                    time.sleep(0.2)
                    if open_orders and open_orders[0]['side'] == 'buy':
                        buy_open_orders[i].append(open_orders[0]['id'])
                except Exception as errorMsg:
                    print('Error：%s' % errorMsg)
                    print('Initializing：No existing buy order whose symbol is %s' % i)
        # 判断买入时机
        if decision_data[0]:
            time_start = time.time()
            for i, j in decision_data[1].items():
                if i in day_growth and float(day_growth[i]) > 8 and i not in high_risk:
                    high_risk[i] = []
                if i in day_growth and float(day_growth[i]) > 8 and len(high_risk[i]) < 3:
                    print("Buy candidate：%s， increased by %s so far" % (i, day_growth[i]))
                    print("strategy suggestion【0】:  at %f price buy%s" % (j, i), file=f)
                    print("strategy suggestion【0】:  at %f price buy%s" % (j, i)) 
                    bid_price = j * buy_signal * buy_signal
                    bid_amount = bid_money / bid_price
                    self.buy_order(i, bid_price, bid_amount)
                    high_risk[i].append(bid_amount)
                    

                elif i == 'USDT' and (j < (decision_data[0][i] * buy_signal)) and (self.balance_free['USDT'] > bid_money):
                    print("%s Price in this round is %s, last round is %s" % (i, str(j), str(decision_data[0][i])), file=f)
                    print("%s Price in this round is %s, last round is %s" % (i, str(j), str(decision_data[0][i])))
                    print("strategy suggestion【1】:  at %f price buy %s" % (j, i), file=f)
                    print("strategy suggestion【1】:  at %f price buy %s" % (j, i))
                    bid_price = j
                    bid_amount = bid_money / bid_price
                    self.buy_order(i, bid_price, bid_amount)
                                
            # 判断卖单提交时机
            if buy_open_orders:
                for symbol, id_list in buy_open_orders.items():
                    if id_list:
                        # print('当前买单的name/id信息：symbol={0}, id_list={1}'.format(symbol, id_list))
                        order_info = jin_binance.fetch_orders(symbol=symbol)
                        # print('依据name/id获得的具体订单信息： {0}'.format(order_info))
                        for order in order_info:
                            if order['side'] == 'buy' and order['status'] == 'closed' and order['id'] in id_list and order['symbol'][:-5] in day_growth:
                                ask_price = 1.02 * order['price']
                                if symbol != 'BNB/USDT':
                                    ask_amount = order['amount'] * (1 - fee)
                                else:
                                    ask_amount = order['amount'] * (1 - fee * 0.75)
                                self.sell_order(symbol, ask_price, ask_amount)
                                if symbol in high_risk:
                                    high_risk[symbol].pop()
                                buy_open_orders[symbol].remove(order['id'])
                                revenue = ask_price * ask_amount * (1 - fee)
                                cost = order['price'] * order['amount']
                                profit = revenue - cost
                                print('【Sell order id=%s symbol=%s price=%s amount=%s filled,theoretically profit=%s】'
                                      % (str(order['id']), symbol, str(ask_price), str(ask_amount), str(profit)), file=f)
                                print('【Sell order id=%s symbol=%s price=%s amount=%s filled,theoretically profit=%s】'
                                      % (str(order['id']), symbol, str(ask_price), str(ask_amount), str(profit)))
                                time.sleep(0.1)
                                self.n_ask += 1
                                n_sell += 1
                            elif order['side'] == 'buy' and order['status'] == 'closed' and order['id'] in id_list:
                                ask_price = sell_signal * order['price']
                                # print('order-price = {0}'.format(order['price']))
                                # print(type(('order-price = {0}'.format(order['price']))))
                                if symbol != 'BNB/USDT':
                                    ask_amount = order['amount'] * (1 - fee)
                                else:
                                    ask_amount = order['amount'] * (1 - fee * 0.75)
                                self.sell_order(symbol, ask_price, ask_amount)
                                if symbol in high_risk:
                                    high_risk[symbol].pop()
                                buy_open_orders[symbol].remove(order['id'])
                                revenue = ask_price * ask_amount * (1 - fee)
                                cost = order['price'] * order['amount']
                                profit = revenue - cost
                                print('【Sell order id=%s symbol=%s price=%s amount=%s filled,theoretically profit=%s】'
                                      % (str(order['id']), symbol, str(ask_price), str(ask_amount), str(profit)), file=f)
                                print('【Sell order id=%s symbol=%s price=%s amount=%s filled,theoretically profit=%s】'
                                      % (str(order['id']), symbol, str(ask_price), str(ask_amount), str(profit)))
                                time.sleep(0.1)
                                self.n_ask += 1
                                n_sell += 1

    def print_info(self):
        global usd_rate, count, total_asset_0, total_asset_1
        self.usd_asset = 0
        usd_increase = 0
        roe = 0
        for i, j in self.balance_total.items():
            if i in self.price_close:
                self.usd_asset = self.usd_asset + j * self.price_close[i]
        self.usd_asset = self.usd_asset + self.balance_total['USDT']
        self.cny_asset = self.usd_asset * usd_rate
        if count == 0:
            total_asset_0 = self.usd_asset
        if count > 0:
            total_asset_1 = self.usd_asset
            roe = (total_asset_1 - total_asset_0) / total_asset_0
            usd_increase = total_asset_1 - total_asset_0

        print('{0}{1}'.format('Account used balance detail:  ', self.balance_result[1]), file=f)
        print('{0}{1}'.format('Account free balance detail:  ', self.balance_result[0]), file=f)
        print('{0}{1}'.format('Account total balance detail:  ', self.balance_result[2]), file=f)
        print('Total asset in USD:  %f' % self.usd_asset, file=f)
        print('Total asset in CNY:  %f' % self.cny_asset, file=f)
        print("Up to now US Dollar profit：%.2f, return:%.2f%%" % (usd_increase, roe), file=f)
        print('This roung buy %d times, sell %d times, total buy %d times，sell %d times，Add up to %d times' % (self.n_bid, self.n_ask, n_buy, n_sell, (n_buy + n_sell)), file=f)
        # print('{0}{1}'.format('Account used balance detail:  ', self.balance_result[1]))
        # print('{0}{1}'.format('Account free balance detail:  ', self.balance_result[0]))
        # print('{0}{1}'.format('Account total balance detail:  ', self.balance_result[2]))
        print('Total asset in USD:  %f' % self.usd_asset)
        print('Total asset in CNY:  %f' % self.cny_asset)
        print("Up to now US Dollar profit：%.2f, return:%.2f%%" % (usd_increase, roe))
        print('This roung buy %d times, sell %d times, total buy %d times，sell %d times，Add up to %d times' % (self.n_bid, self.n_ask, n_buy, n_sell, (n_buy + n_sell)))


def main():
    global f, count, log_name
    my_binance = MyBinance()
    print('USD/CNY exchange rate:  %.4f' % usd_rate)

    while True:
        f = open(log_name, 'a')
        my_binance.n_bid = 0
        my_binance.n_ask = 0
        my_binance.get_all_price()
        my_binance.get_balance()
        my_binance.execute_order()
        my_binance.print_info()
        count += 1

        print('------------The %dth observation round ended------------\n' % count, file=f)
        print('------------The %dth observation round ended------------\n' % count)
        f.close()
        time.sleep(30)

        if count == 10000:
            time_over = time.time()
            temp = datetime.datetime.fromtimestamp(time_over)
            str1 = temp.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

            f = open(log_name, 'a')
            print('==== %s Auto_Trading Ended！====' % str1, file=f)
            f.close()
            print('\nTrading history file located in：\n')
            print(os.path.abspath(log_name))
            print('\n')
            print('==== %s Auto_Trading Ended！====' % str1)
            print('\n')
            break


if __name__ == "__main__":
    main()
