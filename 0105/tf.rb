#!/usr/bin/env ruby
# coding: utf-8

require 'pycall/import'
include PyCall::Import

pyimport 'numpy', as: 'np'
pyimport 'tensorflow', as: 'tf'

# Create 100 phony x, y data points in NumPy, y = x * 0.1 + 0.3
x_data = np.random.rand.(100).astype.(np.float32)
y_data = x_data * 0.1 + 0.3

# Try to find values for W and b that compute y_data = W * x_data + b
# (We know that W should be 0.1 and b 0.3, but Tensorflow will
# figure that out for us.)
w = tf.Variable.(tf.random_uniform.([1], -1.0, 1.0))
b = tf.Variable.(tf.zeros.([1]))
y = w * x_data + b

# Minimize the mean squared errors.
loss = tf.reduce_mean.(tf.square.(y - y_data))
optimizer = tf.train.GradientDescentOptimizer.(0.5)
train = optimizer.minimize.(loss)

# Before starting, initialize the variables. We will 'run' this first.
init = tf.initialize_all_variables.()

# Launch the graph.
sess = tf.Session.()
sess.run.(init)

# Fit the line.
(0..200).each do |step|
  sess.run.(train)
  if step % 20 == 0 then
    puts "#{step}\t#{sess.run.(w)[0]}\t#{sess.run.(b)[0]}"
  end
end
# Learns best fit is W: [0.1], b: [0.3]
